# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'tempfile'
require_relative 'pantry'

module PantryChef
  class StorageError < StandardError
  end

  # Saves and loads pantry and recipe data as local JSON.
  # Owner: Bhaumik — "Save and load pantry and recipes using JSON".
  class Storage
    DEFAULT_PATH = 'data/pantry_chef.json'

    def initialize(path = DEFAULT_PATH)
      @path = File.expand_path(path)
    end

    def load
      state = JSON.parse(File.read(@path, encoding: 'UTF-8'))
      validate_state(state)
      state
    rescue Errno::ENOENT
      { 'pantry' => {}, 'recipes' => {} }
    rescue JSON::ParserError, ValidationError, SystemCallError, IOError => e
      raise StorageError, "Cannot load #{@path}: #{e.message}"
    end

    def save(pantry, recipe_book)
      state = { 'pantry' => pantry.to_h, 'recipes' => recipe_book.to_h }
      validate_state(state)
      content = JSON.pretty_generate(state)
      write_atomically(content)
      true
    rescue JSON::JSONError, ValidationError, SystemCallError, IOError => e
      raise StorageError, "Cannot save #{@path}: #{e.message}"
    end

    private

    def validate_state(state)
      unless state.is_a?(Hash) && state['pantry'].is_a?(Hash) && state['recipes'].is_a?(Hash)
        raise ValidationError, 'State must contain pantry and recipes objects'
      end

      # RecipeBook owns recipe validation and reconstruction after integration.
      Pantry.from_h(state['pantry'])
    end

    def write_atomically(content)
      directory = File.dirname(@path)
      FileUtils.mkdir_p(directory)
      # A closed temporary file on the same filesystem permits replacement on Windows.
      Tempfile.create(['.pantry-chef-', '.tmp'], directory) do |file|
        file.write(content)
        file.flush
        file.fsync
        file.close
        File.rename(file.path, @path)
      end
    end
  end
end
