# frozen_string_literal: true

module PantryChef
    class ValidationError < StandardError; end # Raised by domain classes for invalid input. The CLI is the only place that rescues it.
end

