# frozen_string_literal: true

require_relative 'validation_error'
require_relative 'recipe'

module PantryChef
  # Holds all the recipes. Lookups ignore case, and a name can only be used once.
  # Owner: Gokulan (Add and view recipes, Reject duplicate recipes).
  class RecipeBook
    # Starts empty, or with a list of recipes.
    def initialize(recipes = [])
      @recipes = {}
      recipes.each { |r| add(r) }
    end

    # Adds a recipe. If the name is taken it raises, and the existing recipe stays as it was.
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

    # Finds a recipe by name, ignoring case and extra spaces. Returns nil if none match.
    def find(name)
      key = name.to_s.strip.downcase
      return nil if key.empty?

      @recipes[key]
    end

    # Every recipe, sorted by name.
    def all
      @recipes.values.sort_by(&:name)
    end

    # How many recipes we have.
    def size
      @recipes.size
    end

    def empty?
      @recipes.empty?
    end

    # Recipes keyed by name. Storage puts this under "recipes" in the save file.
    def to_h
      @recipes.transform_values(&:to_h)
    end

    # Rebuilds the book from the hash that to_h gives back.
    def self.from_h(hash)
      raise ValidationError, 'recipe book data must be a hash keyed by recipe name' unless hash.is_a?(Hash)

      new(hash.values.map { |h| Recipe.from_h(h) })
    end
  end
end
