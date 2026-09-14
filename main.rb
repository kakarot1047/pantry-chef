#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/cli'
require_relative 'lib/match_engine'
require_relative 'lib/recipe_book'

storage = PantryChef::Storage.new(ARGV[0] || PantryChef::Storage::DEFAULT_PATH)

begin
  state = storage.load
  pantry = PantryChef::Pantry.from_h(state['pantry'])
  recipe_book = PantryChef::RecipeBook.from_h(state['recipes'])
rescue PantryChef::StorageError, PantryChef::ValidationError => e
  warn "Pantry Chef could not start: #{e.message}"
  warn 'Fix or move the saved data file, then run again.'
  exit 1
end

PantryChef::CLI.new(
  pantry: pantry,
  recipe_book: recipe_book,
  match_engine: PantryChef::MatchEngine.new(pantry: pantry, recipe_book: recipe_book),
  storage: storage
).run
