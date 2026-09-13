# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # Tracks the ingredients the user currently has (name, quantity, unit).
  # Owner: Bhaumik — "Manage pantry items", "Validate pantry input".
  class Pantry
    def initialize(items = {})
      raise ValidationError, 'Pantry items must be a hash' unless items.is_a?(Hash)

      @items = {}
      items.each { |name, record| restore_item(name, record) }
    end

    def add_item(name, quantity, unit)
      name = normalize(name, 'Ingredient name')
      unit = normalize(unit, 'Unit')
      quantity = positive_quantity(quantity)
      existing = @items[name]
      if existing
        ensure_unit(existing, unit)
        quantity = positive_quantity(existing['quantity'] + quantity)
      end
      @items[name] = { 'quantity' => quantity, 'unit' => unit }
      get_item(name)
    end

    def update_item(name, quantity, unit = nil)
      name = normalize(name, 'Ingredient name')
      existing = fetch_item(name)
      quantity = positive_quantity(quantity)
      unit = unit.nil? ? existing['unit'] : normalize(unit, 'Unit')
      @items[name] = { 'quantity' => quantity, 'unit' => unit }
      get_item(name)
    end

    def remove_item(name)
      name = normalize(name, 'Ingredient name')
      fetch_item(name)
      copy_item(@items.delete(name))
    end

    def get_item(name)
      item = @items[normalize(name, 'Ingredient name')]
      copy_item(item) if item
    end

    def sufficient?(name, quantity, unit)
      item = get_item(name)
      quantity = positive_quantity(quantity)
      unit = normalize(unit, 'Unit')
      !!(item && item['unit'] == unit && item['quantity'] >= quantity)
    end

    def consume(name, quantity, unit)
      name = normalize(name, 'Ingredient name')
      item = fetch_item(name)
      quantity = positive_quantity(quantity)
      ensure_unit(item, normalize(unit, 'Unit'))
      raise ValidationError, "Insufficient quantity of #{name}" if item['quantity'] < quantity

      remaining = item['quantity'] - quantity
      remaining.zero? ? remove_item(name) : update_item(name, remaining)
    end

    def to_h
      @items.sort.to_h.transform_values { |item| copy_item(item) }
    end

    alias items to_h

    def self.from_h(hash)
      new(hash)
    end

    private

    def normalize(value, label)
      unless value.is_a?(String) && !value.strip.empty?
        raise ValidationError, "#{label} must be a nonblank string"
      end

      value.strip.downcase
    end

    def positive_quantity(value)
      number = value.is_a?(String) ? Float(value, exception: false) : value
      unless (number.is_a?(Integer) || number.is_a?(Float)) && number.finite? && number.positive?
        raise ValidationError, 'Quantity must be a positive finite number'
      end

      number
    end

    def fetch_item(name)
      @items.fetch(name) { raise ValidationError, "Ingredient not found: #{name}" }
    end

    def ensure_unit(item, unit)
      return if item['unit'] == unit

      raise ValidationError, "Unit mismatch: expected #{item['unit']}, got #{unit}"
    end

    def copy_item(item)
      { 'quantity' => item['quantity'], 'unit' => item['unit'].dup }
    end

    def restore_item(name, record)
      unless record.is_a?(Hash) && record.key?('quantity') && record.key?('unit')
        raise ValidationError, 'Each pantry item needs quantity and unit fields'
      end
      if @items.key?(normalize(name, 'Ingredient name'))
        raise ValidationError, 'Duplicate normalized ingredient name'
      end

      add_item(name, record['quantity'], record['unit'])
    end
  end
end
