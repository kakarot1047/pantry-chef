# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # Small helpers that turn typed text into data, and results back into readable lines.
  # They only work on text. They keep no state and make no decisions.
  module CLIFormatting
    private

    # Turns "flour 200 g, eggs 2 pcs" into a hash. Rejects an ingredient typed twice.
    def parse_ingredients(spec)
      spec.delete('"').split(',').each_with_object({}) do |part, ingredients|
        name, quantity, unit = part.strip.split(/\s+/, 3)
        raise ValidationError, "Bad ingredient '#{part.strip}'. Use: <name> <qty> <unit>" if unit.nil?
        raise ValidationError, "Ingredient '#{name}' is listed twice" if listed?(ingredients, name)

        ingredients[name] = { 'quantity' => quantity, 'unit' => unit }
      end
    end

    # Checks whether a name is already in the list, ignoring case.
    def listed?(ingredients, name)
      ingredients.keys.any? { |key| key.strip.casecmp?(name.strip) }
    end

    # Gives back text like "eggs (need 2 more pcs), milk (need 300 more ml)".
    def format_shortages(shortages)
      shortages.map { |name, info| "#{name} (need #{info['shortage']} more #{info['unit']})" }.join(', ')
    end

    # Gives back text like "flour 200 g, eggs 2 pcs".
    def format_consumed(consumed)
      consumed.map { |name, need| "#{name} #{need['quantity']} #{need['unit']}" }.join(', ')
    end
  end
end
