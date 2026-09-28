# frozen_string_literal: true

module PantryChef
  # Raised when input breaks a rule, like a blank name or a negative quantity.
  # Every class uses this one error, so the CLI only has to catch it in one place.
  class ValidationError < ArgumentError
  end
end
