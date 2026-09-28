# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'tempfile'
require_relative 'pantry'

module PantryChef
  # Raised when the save file cannot be read or written, for example if it is corrupt.
  class StorageError < StandardError
  end

  # Saves the pantry and recipes to one JSON file and loads them back.
  # Owner: Bhaumik (Save and load pantry and recipes using JSON).
  class Storage
    DEFAULT_PATH = 'data/pantry_chef.json'

    # Uses data/pantry_chef.json unless you pass another path.
    def initialize(path = DEFAULT_PATH)
      @path = File.expand_path(path)
    end

    # Reads the save file. No file yet just means a fresh start, so we return empty
    # state. A corrupt file raises StorageError instead of crashing the app.
    def load
      state = JSON.parse(File.read(@path, encoding: 'UTF-8'))
      validate_state(state)
      state
    rescue Errno::ENOENT
      { 'pantry' => {}, 'recipes' => {} }
    rescue JSON::ParserError, ValidationError, SystemCallError, IOError => e
      raise StorageError, "Cannot load #{@path}: #{e.message}"
    end

    # Writes the whole state to disk. Returns true when it worked.
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

    # Checks the data has both a pantry and a recipes section before we trust it.
    def validate_state(state)
      unless state.is_a?(Hash) && state['pantry'].is_a?(Hash) && state['recipes'].is_a?(Hash)
        raise ValidationError, 'State must contain pantry and recipes objects'
      end

      # RecipeBook owns recipe validation and reconstruction after integration.
      Pantry.from_h(state['pantry'])
    end

    # Writes to a temp file first and then swaps it in for the real file.
    # If the program dies halfway through, the old save is still there.
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
