# frozen_string_literal: true

require_relative 'errors'
require_relative 'recipe'

module PantryChef
  # Collection of recipes with case-insensitive lookup and duplicate protection.
  # Owner: Gokulan — "Add and view recipes", "Reject duplicate recipes".
  class RecipeBook
    def initialize(recipes = [])
      @recipes = {}
      recipes.each {|r| add(r)}
    end

  def add(recipe)
      raise ValidationError, 'only Recipe objects can be added' unless recipe.is_a?(Recipe)
      raise ValidationError, "a recipe named '#{recipe.name}' already exists" if @recipes.key?(recipe.name)

      @recipes[recipe.name] = recipe
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
    { 'recipes' => @recipes.transform_values(&:to_h)}
  end

  def self.from_h(hash)
    raise ValidationError, 'recipe book data must be a hash' unless hash.is_a?(Hash)

    entries = hash.transform_keys(&:to_s)['recipes'] || {}
    raise ValidationError, "'recipes' must be a hash keyed by recipe name" unless entries.is_a?(Hash)
    

    new(entries.values.map {|h| Recipe.from_h(h)})
  end
end


end
