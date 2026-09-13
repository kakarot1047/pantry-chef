# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # Compares a Pantry against a RecipeBook: cookable recipes, almost-makeable recipes, shortages.
  # Owner: Yashas — "Show recipes that can be made", "Show almost-makeable recipes", "Cook a recipe".
  class MatchEngine
    def initialize(pantry:, recipe_book:)
      @pantry = pantry
      @recipe_book = recipe_book
    end

    # Returns ingredient name => shortage details for uncovered requirements.
    # Does not mutate the pantry. Unit mismatches count as fully uncovered.
    def shortages_for(recipe)
      recipe.ingredients.each_with_object({}) do |(name, requirement), shortages|
        detail = shortage_detail(name, requirement)
        shortages[name] = detail if detail
      end
    end

    def cookable?(recipe)
      shortages_for(recipe).empty?
    end

    def cookable_recipes
      @recipe_book.all.select { |recipe| cookable?(recipe) }
    end

    # Recipes with more than zero and at most +max_missing+ short ingredient names.
    # Fully cookable recipes are excluded. Raises if max_missing is not a positive integer.
    def almost_makeable(max_missing: 1)
      validate_max_missing!(max_missing)

      @recipe_book.all.filter_map do |recipe|
        shortages = shortages_for(recipe)
        next if shortages.empty? || shortages.size > max_missing

        { 'recipe' => recipe, 'shortages' => shortages }
      end
    end

    # Atomically cook by case-insensitive name. Validates all requirements before any consume.
    def cook(recipe_name)
      recipe = find_recipe!(recipe_name)
      reject_if_shortages!(recipe)
      consume_all!(recipe)
      { 'recipe' => recipe, 'consumed' => recipe.ingredients.transform_values(&:dup) }
    end

    private

    def shortage_detail(name, requirement)
      required = requirement['quantity']
      unit = requirement['unit']
      available = available_quantity(name, unit)
      return if available >= required

      {
        'required' => required,
        'available' => available,
        'shortage' => required - available,
        'unit' => unit
      }
    end

    def available_quantity(name, unit)
      item = @pantry.get_item(name)
      return 0 if item.nil? || item['unit'] != unit

      item['quantity']
    end

    def find_recipe!(recipe_name)
      recipe = @recipe_book.find(recipe_name)
      return recipe if recipe

      raise ValidationError, "Recipe not found: #{recipe_name.to_s.strip.downcase}"
    end

    def reject_if_shortages!(recipe)
      shortages = shortages_for(recipe)
      return if shortages.empty?

      details = shortages.map do |name, info|
        "#{name} (need #{info['shortage']} more #{info['unit']})"
      end.join(', ')
      raise ValidationError, "Cannot cook '#{recipe.name}': missing #{details}"
    end

    def consume_all!(recipe)
      recipe.ingredients.each do |name, requirement|
        @pantry.consume(name, requirement['quantity'], requirement['unit'])
      end
    end

    def validate_max_missing!(max_missing)
      return if max_missing.is_a?(Integer) && max_missing.positive?

      raise ValidationError,
            "max_missing must be a positive integer (got #{max_missing.inspect})"
    end
  end
end
