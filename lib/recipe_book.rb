# frozen_string_literal: true

require_relative 'validation_error'
require_relative 'recipe'

module PantryChef
  # Collection of recipes with case-insensitive lookup and duplicate protection.
  # Owner: Gokulan — "Add and view recipes", "Reject duplicate recipes".
  class RecipeBook
    def initialize(recipes = [])
      @recipes = {}
      recipes.each { |r| add(r) }
    end

    def add(recipe)
      raise ValidationError, 'only Recipe objects can be added' unless recipe.is_a?(Recipe)
      if @recipes.key?(recipe.name)
        raise ValidationError,
              "a recipe named '#{recipe.name}' already exists"
      end

      @recipes[recipe.name] = recipe
    end

    # Removes a recipe by name and returns it, or nil when absent.
    # Used to roll back an addition whose save failed.
    def delete(name)
      key = name.to_s.strip.downcase
      return nil if key.empty?

      @recipes.delete(key)
    end

    def find(name)
      key = name.to_s.strip.downcase
      return nil if key.empty?

      @recipes[key]
    end

    def all
      @recipes.values.sort_by(&:name)
    end

    def size
      @recipes.size
    end

    def empty?
      @recipes.empty?
    end

    def to_h
      @recipes.transform_values(&:to_h)
    end

    def self.from_h(hash)
      raise ValidationError, 'recipe book data must be a hash keyed by recipe name' unless hash.is_a?(Hash)

      new(hash.values.map { |h| Recipe.from_h(h) })
    end
  end
end
