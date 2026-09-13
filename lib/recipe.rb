# frozen_string_literal: true

require_relative 'errors'

module PantryChef
  # A named recipe: servings plus ingredient requirements keyed by ingredient name.
  # Owner: Gokulan — "Add and view recipes".
  class Recipe
    attr_reader :name, :servings, :ingredients

    def initialize(name:, servings:, ingredients:)
      @name = Recipe.normalize_name(name)
      @servings = Recipe.parse_servings(servings)
      @ingredients = Recipe.parse_ingredients(ingredients)
      freeze
    end

    def to_h
      {
        'name' => name,
        'servings' => servings,
        'ingredients' => ingredients.transform_values(&:dup)
      }
    end

    def self.from_h(hash)
      raise ValidationError, 'recipe data must be a hash' unless hash.is_a?(Hash)

      h = hash.transform_keys(&:to_s)
      new(name: h['name'], servings: h['servings'], ingredients: h['ingredients'])
    end

    def ==(other)
      other.is_a?(Recipe) && to_h == other.to_h
    end
    alias eql? ==

    def hash
      to_h.hash
    end

    def self.normalize_name(value, label = 'recipe name')
      text = value.to_s.strip.downcase
      raise ValidationError, "#{label} cannot be blank" if text.empty?

      text
    end
  
    def self.parse_servings(value)
      count = Integer(value.to_s, exception: false)
      raise ValidationError, "servings must be a positive whole number (got #{value.inspect})" if count.nil? || count < 1
      
      count
    end

    def self.parse_ingredients(value)
      raise ValidationError, 'ingredients must be a hash of name => {quantity, unit}' unless value.is_a?(Hash)
      raise ValidationError, 'a recipe needs atleast one ingredient' if value.empty?

      value.each_with_object({}) do |(raw_name, spec), acc|
        name = normalize_name(raw_name, 'ingredient name')
        raise ValidationError, "duplicate ingredient '#{name}' in recipe" if acc.key?(name)

        acc[name] = parse_requirement(name, spec)

      end.freeze
    end

    def self.parse_requirement(name, spec)
      raise ValidationError, "ingredient '#{name}' must be a hash with a quantity and unit" unless spec.is_a?(Hash)
      
      s = spec.transform_keys(&:to_s)
      qty = Float(s['quantity'], exception: false)
      raise ValidationError, "ingredient '#{name}' quantity must be a positive number" if qty.nil? || qty <= 0

      qty = qty.to_i if qty == qty.floor 
      { 'quantity' => qty, 'unit' => normalize_name(s['unit'], "ingredient '#{name}' unit")}.freeze
    end
    private_class_method :parse_requirement

  end
end
