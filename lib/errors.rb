# frozen_string_literal: true

module PantryChef
  # Raised by domain classes for invalid input. The CLI is the only place that rescues it.
  class ValidationError < ArgumentError; end
end
