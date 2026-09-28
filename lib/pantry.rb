# frozen_string_literal: true

require_relative 'validation_error'

module PantryChef
  # Keeps track of which ingredients the user has, how much, and in what unit.
  # Owner: Bhaumik (Manage pantry items, Validate pantry input).
  class Pantry
    # Starts empty, or rebuilds a pantry from saved data such as
    # { "flour" => { "quantity" => 500, "unit" => "g" } }.
    def initialize(items = {})
      raise ValidationError, 'Pantry items must be a hash' unless items.is_a?(Hash)

      @items = {}
      items.each { |name, record| restore_item(name, record) }
    end

    # Adds stock. If the item is already here, the new amount goes on top.
    # The unit has to match what is stored, because we do not convert units.
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

    # Sets an item to an exact amount instead of adding to it.
    # Leave the unit out to keep the current one.
    def update_item(name, quantity, unit = nil)
      name = normalize(name, 'Ingredient name')
      existing = fetch_item(name)
      quantity = positive_quantity(quantity)
      unit = unit.nil? ? existing['unit'] : normalize(unit, 'Unit')
      @items[name] = { 'quantity' => quantity, 'unit' => unit }
      get_item(name)
    end

    # Deletes an item and returns what it held. Raises if the item is not here.
    def remove_item(name)
      name = normalize(name, 'Ingredient name')
      fetch_item(name)
      copy_item(@items.delete(name))
    end

    # Looks up one item. Returns a copy, or nil if we do not have it.
    def get_item(name)
      item = @items[normalize(name, 'Ingredient name')]
      copy_item(item) if item
    end

    # True when we have at least this much of the item, in the same unit.
    def sufficient?(name, quantity, unit)
      item = get_item(name)
      quantity = positive_quantity(quantity)
      unit = normalize(unit, 'Unit')
      !!(item && item['unit'] == unit && item['quantity'] >= quantity)
    end

    # Uses up part of an item, for example when cooking. Refuses if there is
    # not enough, and removes the item once it runs out.
    def consume(name, quantity, unit)
      name = normalize(name, 'Ingredient name')
      item = fetch_item(name)
      quantity = positive_quantity(quantity)
      ensure_unit(item, normalize(unit, 'Unit'))
      raise ValidationError, "Insufficient quantity of #{name}" if item['quantity'] < quantity

      remaining = item['quantity'] - quantity
      remaining.zero? ? remove_item(name) : update_item(name, remaining)
    end

    # Every item sorted by name, as copies so nobody can change the pantry by accident.
    def to_h
      @items.sort.to_h.transform_values { |item| copy_item(item) }
    end

    alias items to_h

    # Rebuilds a pantry from the hash that to_h gives back.
    def self.from_h(hash)
      new(hash)
    end

    private

    # Trims and lowercases a name so "Flour " and "flour" mean the same thing.
    def normalize(value, label)
      unless value.is_a?(String) && !value.strip.empty?
        raise ValidationError, "#{label} must be a nonblank string"
      end

      value.strip.downcase
    end

    # Accepts a number or numeric text and makes sure it is above zero.
    def positive_quantity(value)
      number = value.is_a?(String) ? Float(value, exception: false) : value
      unless (number.is_a?(Integer) || number.is_a?(Float)) && number.finite? && number.positive?
        raise ValidationError, 'Quantity must be a positive finite number'
      end

      number
    end

    # Like get_item, but raises when the item is missing.
    def fetch_item(name)
      @items.fetch(name) { raise ValidationError, "Ingredient not found: #{name}" }
    end

    # Stops us from adding grams to something that is stored in cups.
    def ensure_unit(item, unit)
      return if item['unit'] == unit

      raise ValidationError, "Unit mismatch: expected #{item['unit']}, got #{unit}"
    end

    # A fresh copy, so outside code never holds on to our internal hash.
    def copy_item(item)
      { 'quantity' => item['quantity'], 'unit' => item['unit'].dup }
    end

    # Used while loading saved data. Checks each record before adding it.
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
