# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # Turns command text into domain input and domain results into display strings.
  # Pure text handling: no state, no rules, no I/O.
  module CLIFormatting
    private

    def parse_ingredients(spec)
      spec.delete('"').split(',').each_with_object({}) do |part, ingredients|
        name, quantity, unit = part.strip.split(/\s+/, 3)
        raise ValidationError, "Bad ingredient '#{part.strip}'. Use: <name> <qty> <unit>" if unit.nil?
        raise ValidationError, "Ingredient '#{name}' is listed twice" if listed?(ingredients, name)

        ingredients[name] = { 'quantity' => quantity, 'unit' => unit }
      end
    end

    def listed?(ingredients, name)
      ingredients.keys.any? { |key| key.strip.casecmp?(name.strip) }
    end

    def format_shortages(shortages)
      shortages.map { |name, info| "#{name} (need #{info['shortage']} more #{info['unit']})" }.join(', ')
    end

    def format_consumed(consumed)
      consumed.map { |name, need| "#{name} #{need['quantity']} #{need['unit']}" }.join(', ')
    end
  end
end
