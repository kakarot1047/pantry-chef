# frozen_string_literal: true

RSpec.describe PantryChef::RecipeBook do
  subject(:book) { described_class.new }

  let(:flour) { { 'quantity' => 200, 'unit' => 'g' } }
  let(:pancakes) { PantryChef::Recipe.new(name: 'Pancakes', servings: 4, ingredients: { 'flour' => flour }) }
  let(:omelette) { PantryChef::Recipe.new(name: 'omelette', servings: 1, ingredients: { 'eggs' => { 'quantity' => 3, 'unit' => 'pcs' } }) }

  describe '#add and #find' do
    it 'adds a recipe and retrieves it' do
      book.add(pancakes)
      expect(book.find('pancakes')).to eq(pancakes)
    end

    it 'looks up case-insensitively and ignores surrounding whitespace' do
      book.add(pancakes)
      expect(book.find('PANCAKES')).to eq(pancakes)
      expect(book.find('  Pancakes ')).to eq(pancakes)
    end

    it 'returns nil for an unknown or blank name' do
      expect(book.find('waffles')).to be_nil
      expect(book.find('')).to be_nil
      expect(book.find(nil)).to be_nil
    end

    it 'rejects things that are not recipes' do
      expect { book.add('pancakes') }.to raise_error(PantryChef::ValidationError, /only Recipe objects/)
      expect(book).to be_empty
    end
  end

  describe 'duplicate protection' do
    let(:pancakes_v2) { PantryChef::Recipe.new(name: 'PANCAKES', servings: 8, ingredients: { 'flour' => flour }) }

    before { book.add(pancakes) }

    it 'rejects a recipe whose name already exists, ignoring case' do
      expect { book.add(pancakes_v2) }.to raise_error(PantryChef::ValidationError, /already exists/)
    end

    it 'leaves the existing recipe unchanged and keeps exactly one' do
      begin
        book.add(pancakes_v2)
      rescue PantryChef::ValidationError
        nil
      end
      expect(book.size).to eq(1)
      expect(book.find('pancakes').servings).to eq(4)
    end

    it 'rejects duplicates supplied to the constructor' do
      expect do
        described_class.new([pancakes, pancakes_v2])
      end.to raise_error(PantryChef::ValidationError, /already exists/)
    end
  end

  describe '#all' do
    it 'returns recipes sorted by name' do
      book.add(pancakes)
      book.add(omelette)
      expect(book.all.map(&:name)).to eq(%w[omelette pancakes])
    end

    it 'is empty for a new book' do
      expect(book.all).to eq([])
      expect(book).to be_empty
    end
  end

  describe 'serialization' do
    it 'round-trips through to_h and from_h' do
      book.add(pancakes)
      book.add(omelette)
      expect(described_class.from_h(book.to_h).all).to eq(book.all)
    end

    it 'produces a map keyed by recipe name (Storage adds the outer "recipes" key)' do
      book.add(pancakes)
      expect(book.to_h).to eq('pancakes' => pancakes.to_h)
    end

    it 'loads an empty book when the recipes key is missing' do
      expect(described_class.from_h({})).to be_empty
    end

    it 'rejects malformed data' do
      expect do
        described_class.from_h([])
      end.to raise_error(PantryChef::ValidationError, /keyed by recipe name/)
      expect do
        described_class.from_h(nil)
      end.to raise_error(PantryChef::ValidationError, /keyed by recipe name/)
    end
  end
end
