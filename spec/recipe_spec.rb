# frozen_string_literal: true

RSpec.describe PantryChef::Recipe do
  let(:flour) { { 'quantity' => 200, 'unit' => 'g' } }
  let(:eggs)  { { 'quantity' => 2, 'unit' => 'pcs' } }

  def build(**overrides)
    described_class.new(name: 'Pancakes', servings: 4,
                        ingredients: { 'flour' => flour, 'eggs' => eggs }, **overrides)
  end

  describe 'happy path' do
    it 'stores name, servings, and ingredients' do
      recipe = build
      expect(recipe.name).to eq('pancakes')
      expect(recipe.servings).to eq(4)
      expect(recipe.ingredients).to eq('flour' => flour, 'eggs' => eggs)
    end

    it 'normalizes recipe, ingredient, and unit names' do
      recipe = build(name: '  Pancakes ',
                     ingredients: { ' Flour ' => { 'quantity' => 200,
                                                   'unit' => ' G ' } })
      expect(recipe.name).to eq('pancakes')
      expect(recipe.ingredients).to eq('flour' => { 'quantity' => 200, 'unit' => 'g' })
    end

    it 'accepts symbol keys and numeric strings' do
      recipe = build(servings: '2', ingredients: { flour: { quantity: '150.5', unit: 'g' } })
      expect(recipe.servings).to eq(2)
      expect(recipe.ingredients['flour']).to eq('quantity' => 150.5, 'unit' => 'g')
    end

    it 'is immutable' do
      recipe = build
      expect(recipe).to be_frozen
      expect { recipe.ingredients['sugar'] = flour }.to raise_error(FrozenError)
    end

    it 'round-trips through to_h and from_h' do
      recipe = build
      expect(described_class.from_h(recipe.to_h)).to eq(recipe)
    end

    it 'does not expose internal state through to_h' do
      recipe = build
      recipe.to_h['ingredients']['flour']['quantity'] = 999
      expect(recipe.ingredients['flour']['quantity']).to eq(200)
    end

    it 'freezes name, ingredient names, and units' do
      recipe = build
      expect(recipe.name).to be_frozen
      expect(recipe.ingredients.keys).to all(be_frozen)
      expect(recipe.ingredients.values.map { |v| v['unit'] }).to all(be_frozen)
    end

    it 'returns independent string copies from to_h' do
      recipe = build
      h = recipe.to_h
      h['name'] << 'x'
      h['ingredients']['flour']['unit'] << 'x'
      expect(recipe.name).to eq('pancakes')
      expect(recipe.ingredients['flour']['unit']).to eq('g')
    end
  end

  describe 'validation' do
    it 'rejects a blank name' do
      expect { build(name: '   ') }.to raise_error(PantryChef::ValidationError, /name cannot be blank/)
      expect { build(name: nil) }.to raise_error(PantryChef::ValidationError, /name cannot be blank/)
    end

    it 'rejects non-positive or non-integer servings' do
      [0, -1, 'four', 2.5, nil].each do |bad|
        expect do
          build(servings: bad)
        end.to raise_error(PantryChef::ValidationError,
                           /servings must be a positive whole number/)
      end
    end

    it 'rejects missing or empty ingredients' do
      expect { build(ingredients: {}) }.to raise_error(PantryChef::ValidationError, /atleast one ingredient/)
      expect { build(ingredients: nil) }.to raise_error(PantryChef::ValidationError, /must be a hash/)
      expect { build(ingredients: [flour]) }.to raise_error(PantryChef::ValidationError, /must be a hash/)
    end

    it 'rejects a malformed ingredient requirement' do
      expect do
        build(ingredients: { 'flour' => 200 })
      end.to raise_error(PantryChef::ValidationError, /must be a hash/)
      expect { build(ingredients: { 'flour' => { 'unit' => 'g' } }) }
        .to raise_error(PantryChef::ValidationError, /quantity must be a positive finite number/)
    end

    it 'rejects non-positive or non-numeric quantities' do
      [0, -5, 'lots', nil].each do |bad|
        expect { build(ingredients: { 'flour' => { 'quantity' => bad, 'unit' => 'g' } }) }
          .to raise_error(PantryChef::ValidationError, /quantity must be a positive finite number/)
      end
    end

    it 'rejects infinite and NaN quantities' do
      [Float::INFINITY, -Float::INFINITY, Float::NAN, 'Infinity', 'NaN'].each do |bad|
        expect { build(ingredients: { 'flour' => { 'quantity' => bad, 'unit' => 'g' } }) }
          .to raise_error(PantryChef::ValidationError, /positive finite number/)
      end
    end

    it 'rejects blank units' do
      expect { build(ingredients: { 'flour' => { 'quantity' => 1, 'unit' => ' ' } }) }
        .to raise_error(PantryChef::ValidationError, /unit cannot be blank/)
    end

    it 'rejects blank ingredient names' do
      expect do
        build(ingredients: { '' => flour })
      end.to raise_error(PantryChef::ValidationError,
                         /ingredient name cannot be blank/)
    end

    it 'rejects the same ingredient listed twice under different casing' do
      expect { build(ingredients: { 'Flour' => flour, 'flour' => flour }) }
        .to raise_error(PantryChef::ValidationError, /duplicate ingredient/)
    end

    it 'rejects non-hash input to from_h' do
      expect do
        described_class.from_h('pancakes')
      end.to raise_error(PantryChef::ValidationError, /must be a hash/)
    end
  end
end
