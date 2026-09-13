# frozen_string_literal: true

require 'tmpdir'
require 'json'

# Cross-class integration: real Pantry, Recipe, RecipeBook and Storage objects, no doubles.
# Guards the single-envelope save format and the shared ValidationError contract.
RSpec.describe 'Pantry Chef persistence integration' do
  let(:flour) { { 'quantity' => 200, 'unit' => 'g' } }

  def flatbread
    PantryChef::Recipe.new(name: 'Flatbread', servings: 2, ingredients: { 'flour' => flour })
  end

  def stocked_pantry
    PantryChef::Pantry.new.tap { |pantry| pantry.add_item('flour', 500, 'g') }
  end

  it 'saves the documented single-envelope structure' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'data', 'pantry_chef.json')
      book = PantryChef::RecipeBook.new([flatbread])

      PantryChef::Storage.new(path).save(stocked_pantry, book)

      raw = JSON.parse(File.read(path))
      expect(raw.keys).to contain_exactly('pantry', 'recipes')
      expect(raw['pantry']).to eq('flour' => { 'quantity' => 500, 'unit' => 'g' })
      expect(raw['recipes']).to eq(
        'flatbread' => { 'name' => 'flatbread', 'servings' => 2,
                         'ingredients' => { 'flour' => flour } }
      )
    end
  end

  it 'reconstructs the same pantry and recipes from a saved file' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'data', 'pantry_chef.json')
      PantryChef::Storage.new(path).save(stocked_pantry, PantryChef::RecipeBook.new([flatbread]))

      state = PantryChef::Storage.new(path).load
      pantry = PantryChef::Pantry.from_h(state['pantry'])
      book = PantryChef::RecipeBook.from_h(state['recipes'])

      expect(pantry.get_item('flour')).to eq('quantity' => 500, 'unit' => 'g')
      expect(book.all.map(&:name)).to eq(['flatbread'])
      expect(book.find('FLATBREAD').ingredients).to eq('flour' => flour)
      expect(book.find('flatbread').servings).to eq(2)
    end
  end

  it 'does not silently discard recipes when several are saved' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'data', 'pantry_chef.json')
      book = PantryChef::RecipeBook.new
      %w[flatbread pancakes omelette].each do |name|
        book.add(PantryChef::Recipe.new(name: name, servings: 1, ingredients: { 'flour' => flour }))
      end

      PantryChef::Storage.new(path).save(PantryChef::Pantry.new, book)
      state = PantryChef::Storage.new(path).load

      expect(PantryChef::RecipeBook.from_h(state['recipes']).all.map(&:name))
        .to eq(%w[flatbread omelette pancakes])
    end
  end

  it 'raises the shared ValidationError for invalid quantities in both domains' do
    expect { PantryChef::Pantry.new.add_item('flour', -1, 'g') }
      .to raise_error(PantryChef::ValidationError)
    expect { PantryChef::Recipe.new(name: 'x', servings: 1, ingredients: { 'flour' => { 'quantity' => Float::INFINITY, 'unit' => 'g' } }) }
      .to raise_error(PantryChef::ValidationError)
    expect(PantryChef::ValidationError.superclass).to eq(ArgumentError)
  end

  it 'does not let mutated serialized strings change the original recipe' do
    recipe = flatbread
    serialized = recipe.to_h
    serialized['name'] << 'x'
    serialized['ingredients']['flour']['unit'] << 'x'

    expect(recipe.name).to eq('flatbread')
    expect(recipe.ingredients['flour']['unit']).to eq('g')
  end

  it 'preserves the existing recipe when a duplicate is rejected' do
    book = PantryChef::RecipeBook.new([flatbread])
    duplicate = PantryChef::Recipe.new(name: 'FLATBREAD', servings: 99, ingredients: { 'flour' => flour })

    expect { book.add(duplicate) }.to raise_error(PantryChef::ValidationError, /already exists/)
    expect(book.size).to eq(1)
    expect(book.find('flatbread').servings).to eq(2)
  end
end
