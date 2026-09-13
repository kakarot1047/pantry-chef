# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PantryChef::MatchEngine do
  def recipe(name, ingredients, servings: 2)
    PantryChef::Recipe.new(name: name, servings: servings, ingredients: ingredients)
  end

  def pantry_with(items)
    PantryChef::Pantry.new(items)
  end

  def engine_for(pantry_items, recipes)
    pantry = pantry_with(pantry_items)
    book = PantryChef::RecipeBook.new(recipes)
    [described_class.new(pantry: pantry, recipe_book: book), pantry, book]
  end

  let(:flatbread) do
    recipe('Flatbread', {
             'flour' => { 'quantity' => 400, 'unit' => 'g' },
             'water' => { 'quantity' => 200, 'unit' => 'ml' }
           })
  end

  describe '#shortages_for and #cookable?' do
    it 'marks Flatbread cookable when flour 500 g and water 300 ml are available' do
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      expect(engine.cookable?(flatbread)).to be true
      expect(engine.shortages_for(flatbread)).to eq({})
      expect(pantry.to_h).to eq(
        'flour' => { 'quantity' => 500, 'unit' => 'g' },
        'water' => { 'quantity' => 300, 'unit' => 'ml' }
      )
    end

    it 'is not cookable when flour is only 100 g' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 100, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      expect(engine.cookable?(flatbread)).to be false
      expect(engine.shortages_for(flatbread)).to eq(
        'flour' => {
          'required' => 400,
          'available' => 100,
          'shortage' => 300,
          'unit' => 'g'
        }
      )
    end

    it 'excludes a recipe when an ingredient is missing' do
      engine, = engine_for(
        { 'flour' => { 'quantity' => 500, 'unit' => 'g' } },
        [flatbread]
      )

      expect(engine.cookable?(flatbread)).to be false
      expect(engine.shortages_for(flatbread)).to include(
        'water' => hash_including(
          'required' => 200,
          'available' => 0,
          'shortage' => 200,
          'unit' => 'ml'
        )
      )
    end

    it 'excludes a recipe on unit mismatch' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'kg' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      expect(engine.cookable?(flatbread)).to be false
      expect(engine.shortages_for(flatbread)['flour']).to eq(
        'required' => 400,
        'available' => 0,
        'shortage' => 400,
        'unit' => 'g'
      )
    end

    it 'treats exact quantities as sufficient' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 400, 'unit' => 'g' },
          'water' => { 'quantity' => 200, 'unit' => 'ml' }
        },
        [flatbread]
      )

      expect(engine.cookable?(flatbread)).to be true
      expect(engine.shortages_for(flatbread)).to be_empty
    end

    it 'does not modify pantry state during availability checks' do
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 100, 'unit' => 'g' },
          'water' => { 'quantity' => 50, 'unit' => 'ml' }
        },
        [flatbread]
      )
      before = pantry.to_h

      engine.cookable?(flatbread)
      engine.shortages_for(flatbread)
      engine.cookable_recipes
      engine.almost_makeable(max_missing: 2)

      expect(pantry.to_h).to eq(before)
    end
  end

  describe '#cookable_recipes' do
    it 'filters multiple recipes correctly' do
      soup = recipe('Soup', {
                      'water' => { 'quantity' => 100, 'unit' => 'ml' },
                      'salt' => { 'quantity' => 1, 'unit' => 'g' }
                    })
      cake = recipe('Cake', {
                      'flour' => { 'quantity' => 200, 'unit' => 'g' },
                      'sugar' => { 'quantity' => 100, 'unit' => 'g' }
                    })

      engine, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' },
          'salt' => { 'quantity' => 5, 'unit' => 'g' }
        },
        [flatbread, soup, cake]
      )

      expect(engine.cookable_recipes.map(&:name)).to eq(%w[flatbread soup])
    end
  end

  describe '#almost_makeable' do
    let(:three_ingredient) do
      recipe('Stew', {
               'carrot' => { 'quantity' => 2, 'unit' => 'pc' },
               'potato' => { 'quantity' => 3, 'unit' => 'pc' },
               'onion' => { 'quantity' => 1, 'unit' => 'pc' }
             })
    end

    it 'includes a three-ingredient recipe with exactly one missing ingredient at max_missing: 1' do
      engine, = engine_for(
        {
          'carrot' => { 'quantity' => 2, 'unit' => 'pc' },
          'potato' => { 'quantity' => 3, 'unit' => 'pc' }
        },
        [three_ingredient]
      )

      results = engine.almost_makeable(max_missing: 1)
      expect(results.size).to eq(1)
      expect(results.first['recipe'].name).to eq('stew')
      expect(results.first['shortages']).to eq(
        'onion' => {
          'required' => 1,
          'available' => 0,
          'shortage' => 1,
          'unit' => 'pc'
        }
      )
    end

    it 'reports insufficient quantity as the difference' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 100, 'unit' => 'g' },
          'water' => { 'quantity' => 200, 'unit' => 'ml' }
        },
        [flatbread]
      )

      results = engine.almost_makeable(max_missing: 1)
      expect(results.first['shortages']['flour']['shortage']).to eq(300)
    end

    it 'excludes a recipe with two shortages at threshold 1 and includes it at threshold 2' do
      engine, = engine_for(
        { 'carrot' => { 'quantity' => 2, 'unit' => 'pc' } },
        [three_ingredient]
      )

      expect(engine.almost_makeable(max_missing: 1)).to be_empty
      expect(engine.almost_makeable(max_missing: 2).map { |r| r['recipe'].name }).to eq(%w[stew])
    end

    it 'does not include a fully cookable recipe' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      expect(engine.almost_makeable(max_missing: 1)).to be_empty
    end

    it 'counts shortages by ingredient name even when the quantity deficit is large' do
      engine, = engine_for(
        {
          'flour' => { 'quantity' => 1, 'unit' => 'g' },
          'water' => { 'quantity' => 200, 'unit' => 'ml' }
        },
        [flatbread]
      )

      results = engine.almost_makeable(max_missing: 1)
      expect(results.size).to eq(1)
      expect(results.first['shortages'].keys).to eq(%w[flour])
    end

    it 'rejects a zero or negative max_missing threshold' do
      engine, = engine_for({}, [flatbread])

      expect { engine.almost_makeable(max_missing: 0) }
        .to raise_error(PantryChef::ValidationError, /max_missing must be a positive integer/)
      expect { engine.almost_makeable(max_missing: -1) }
        .to raise_error(PantryChef::ValidationError, /max_missing must be a positive integer/)
    end

    it 'leaves the pantry unchanged' do
      engine, pantry, = engine_for(
        { 'flour' => { 'quantity' => 100, 'unit' => 'g' } },
        [flatbread]
      )
      before = pantry.to_h

      engine.almost_makeable(max_missing: 2)

      expect(pantry.to_h).to eq(before)
    end
  end

  describe '#cook' do
    it 'deducts Flatbread ingredients and leaves 100 g flour' do
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      result = engine.cook('flatbread')

      expect(result['recipe'].name).to eq('flatbread')
      expect(pantry.get_item('flour')).to eq('quantity' => 100, 'unit' => 'g')
      expect(pantry.get_item('water')).to eq('quantity' => 100, 'unit' => 'ml')
    end

    it 'fails a second cook attempt and leaves flour at 100 g' do
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'water' => { 'quantity' => 300, 'unit' => 'ml' }
        },
        [flatbread]
      )

      engine.cook('Flatbread')
      expect { engine.cook('flatbread') }
        .to raise_error(PantryChef::ValidationError, /Cannot cook/)

      expect(pantry.get_item('flour')).to eq('quantity' => 100, 'unit' => 'g')
    end

    it 'deducts nothing when a multi-ingredient recipe fails on a later ingredient' do
      pasta = recipe('Pasta', {
                       'flour' => { 'quantity' => 200, 'unit' => 'g' },
                       'egg' => { 'quantity' => 2, 'unit' => 'pc' },
                       'salt' => { 'quantity' => 5, 'unit' => 'g' }
                     })
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 500, 'unit' => 'g' },
          'egg' => { 'quantity' => 2, 'unit' => 'pc' },
          'salt' => { 'quantity' => 1, 'unit' => 'g' }
        },
        [pasta]
      )
      before = pantry.to_h

      expect { engine.cook('pasta') }.to raise_error(PantryChef::ValidationError)
      expect(pantry.to_h).to eq(before)
    end

    it 'handles a missing recipe name gracefully' do
      engine, pantry, = engine_for(
        { 'flour' => { 'quantity' => 500, 'unit' => 'g' } },
        [flatbread]
      )
      before = pantry.to_h

      expect { engine.cook('lasagna') }
        .to raise_error(PantryChef::ValidationError, /Recipe not found/)
      expect(pantry.to_h).to eq(before)
    end

    it 'looks up recipes case-insensitively and deducts each ingredient once' do
      engine, pantry, = engine_for(
        {
          'flour' => { 'quantity' => 400, 'unit' => 'g' },
          'water' => { 'quantity' => 200, 'unit' => 'ml' }
        },
        [flatbread]
      )

      engine.cook('FLATBREAD')

      expect(pantry.get_item('flour')).to be_nil
      expect(pantry.get_item('water')).to be_nil
    end
  end
end
