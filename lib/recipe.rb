# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # One recipe: its name, how many it serves, and the ingredients it needs.
  # Owner: Gokulan (Add and view recipes).
  class Recipe
    attr_reader :name, :servings, :ingredients

    # Checks every field and cleans up the names, then freezes the recipe
    # so nothing can change it later.
    def initialize(name:, servings:, ingredients:)
      @name = Recipe.normalize_name(name)
      @servings = Recipe.parse_servings(servings)
      @ingredients = Recipe.parse_ingredients(ingredients)
      freeze
    end

    # Plain hash for saving. Strings are copied, so editing the result leaves the recipe alone.
    def to_h
      {
        'name' => name.dup,
        'servings' => servings,
        'ingredients' => ingredients.to_h do |k, v|
          [k.dup, { 'quantity' => v['quantity'], 'unit' => v['unit'].dup }]
        end
      }
    end

    # Builds a recipe back from a saved hash.
    def self.from_h(hash)
      raise ValidationError, 'recipe data must be a hash' unless hash.is_a?(Hash)

      h = hash.transform_keys(&:to_s)
      new(name: h['name'], servings: h['servings'], ingredients: h['ingredients'])
    end

    # Two recipes are equal when all of their data matches.
    def ==(other)
      other.is_a?(Recipe) && to_h == other.to_h
    end
    alias eql? ==

    # Keeps equal recipes working the same way inside hashes and sets.
    def hash
      to_h.hash
    end

    # Trims and lowercases a name, and rejects a blank one.
    def self.normalize_name(value, label = 'recipe name')
      text = value.to_s.strip.downcase
      raise ValidationError, "#{label} cannot be blank" if text.empty?

      text.freeze
    end

    # Servings must be a whole number of at least 1. "4" is fine, 2.5 is not.
    def self.parse_servings(value)
      count = Integer(value.to_s, exception: false)
      if count.nil? || count < 1
        raise ValidationError,
              "servings must be a positive whole number (got #{value.inspect})"
      end

      count
    end

    # Checks the ingredient list. It needs at least one item and no repeats.
    def self.parse_ingredients(value)
      raise ValidationError, 'ingredients must be a hash of name => {quantity, unit}' unless value.is_a?(Hash)
      raise ValidationError, 'a recipe needs atleast one ingredient' if value.empty?

      value.each_with_object({}) do |(raw_name, spec), acc|
        name = normalize_name(raw_name, 'ingredient name')
        raise ValidationError, "duplicate ingredient '#{name}' in recipe" if acc.key?(name)

        acc[name] = parse_requirement(name, spec)
      end.freeze
    end

    # Checks one ingredient has a valid quantity and unit.
    def self.parse_requirement(name, spec)
      unless spec.is_a?(Hash)
        raise ValidationError,
              "ingredient '#{name}' must be a hash with quantity and unit"
      end

      s = spec.transform_keys(&:to_s)
      { 'quantity' => parse_quantity(name, s['quantity']),
        'unit' => normalize_name(s['unit'], "ingredient '#{name}' unit") }.freeze
    end
    private_class_method :parse_requirement

    # The amount must be a real number above zero. Whole numbers are kept as integers.
    def self.parse_quantity(name, value)
      qty = Float(value, exception: false)
      if qty.nil? || !qty.finite? || qty <= 0
        raise ValidationError, "ingredient '#{name}' quantity must be a positive finite number"
      end

      qty == qty.floor ? qty.to_i : qty
    end
    private_class_method :parse_quantity
  end
end
