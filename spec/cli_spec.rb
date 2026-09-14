# frozen_string_literal: true

require 'stringio'
require 'tmpdir'

RSpec.describe PantryChef::CLI do
  let(:output) { StringIO.new }
  let(:pantry) { PantryChef::Pantry.new }
  let(:recipe_book) { PantryChef::RecipeBook.new }
  let(:engine) { PantryChef::MatchEngine.new(pantry: pantry, recipe_book: recipe_book) }

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def storage
    @storage ||= PantryChef::Storage.new(File.join(@dir, 'data', 'pantry_chef.json'))
  end

  def cli(input = StringIO.new)
    PantryChef::CLI.new(pantry: pantry, recipe_book: recipe_book, match_engine: engine,
                        storage: storage, input: input, output: output)
  end

  def run(*lines)
    subject = cli
    lines.each { |line| subject.run_command(line) }
    output.string
  end

  describe 'the command loop' do
    it 'prints the menu covering pantry, recipes, matching, cooking, and exit' do
      expect(run('help')).to include('Pantry:', 'Recipes:', 'Matching:', 'Cooking:', 'quit')
    end

    it 'reports an unknown selection without raising' do
      expect { cli.run_command('dance') }.not_to raise_error
      expect(output.string).to include("Unknown command 'dance'")
    end

    it 'ignores a blank line' do
      expect(run('   ')).to eq('')
    end

    it 'returns :quit for quit and exit' do
      expect(cli.run_command('quit')).to eq(:quit)
      expect(cli.run_command('EXIT')).to eq(:quit)
    end

    it 'stops cleanly at end of input' do
      cli(StringIO.new("pantry\n")).run
      expect(output.string).to include('Goodbye.')
    end
  end

  describe 'pantry commands' do
    it 'stocks an ingredient and lists it' do
      expect(run('add flour 500 g', 'pantry')).to include('flour: 500.0 g')
    end

    it 'updates and removes an ingredient' do
      expect(run('add flour 500 g', 'update flour 200', 'pantry')).to include('flour: 200.0 g')
      expect(run('remove flour', 'pantry')).to include('Pantry is empty.')
    end

    it 'reports an empty pantry' do
      expect(run('pantry')).to include('Pantry is empty.')
    end

    it 'reports usage when arguments are missing' do
      expect(run('add flour')).to include('Usage: add')
      expect(run('remove')).to include('Usage: remove')
    end

    it 'reports a domain validation failure instead of crashing' do
      expect(run('add flour lots g')).to include('Error: Quantity must be a positive finite number')
      expect(pantry.items).to be_empty
    end
  end

  describe 'recipe commands' do
    let(:pancakes) { 'add-recipe pancakes 4 "flour 200 g, eggs 2 pcs"' }

    it 'adds, lists and shows a recipe case-insensitively' do
      expect(run(pancakes, 'recipes')).to include('pancakes (serves 4)')
      expect(run('show-recipe PANCAKES')).to include('flour: 200 g', 'eggs: 2 pcs')
    end

    it 'reports an unknown recipe' do
      expect(run('show-recipe ghost')).to include('Recipe not found: ghost')
    end

    it 'rejects a duplicate name and keeps the original' do
      run(pancakes)
      expect(run('add-recipe PANCAKES 9 "flour 1 g"')).to include('already exists')
      expect(recipe_book.size).to eq(1)
      expect(recipe_book.find('pancakes').servings).to eq(4)
    end

    it 'reports a malformed ingredient list' do
      expect(run('add-recipe soup 2 "water"')).to include('Use: <name> <qty> <unit>')
      expect(recipe_book).to be_empty
    end
  end

  describe 'matching commands' do
    before do
      run('add flour 500 g', 'add-recipe flatbread 2 "flour 200 g"',
          'add-recipe pancakes 4 "flour 200 g, milk 300 ml"')
    end

    it 'lists what can be made now' do
      expect(run('can-make')).to include('flatbread')
    end

    it 'lists what is almost makeable with the shortfall' do
      expect(run('almost')).to include('pancakes - missing milk (need 300 more ml)')
    end

    it 'rejects a non-positive limit' do
      expect(run('almost 0')).to include('Error: max_missing must be a positive integer')
    end
  end

  describe 'cooking' do
    before { run('add flour 500 g', 'add-recipe flatbread 2 "flour 200 g"') }

    it 'deducts the ingredients and reports what was used' do
      expect(run('cook flatbread')).to include('Cooked flatbread. Used flour 200 g.')
      expect(pantry.get_item('flour')['quantity']).to eq(300.0)
    end

    it 'refuses an unaffordable recipe and changes nothing' do
      run('add-recipe cake 1 "flour 900 g"')
      expect(run('cook cake')).to include('Error: Cannot cook', 'flour')
      expect(pantry.get_item('flour')['quantity']).to eq(500.0)
    end

    it 'reports an unknown recipe' do
      expect(run('cook ghost')).to include('Error: Recipe not found: ghost')
    end
  end

  describe 'persistence' do
    it 'saves after a mutating command so a fresh session sees it' do
      run('add flour 500 g', 'add-recipe flatbread 2 "flour 200 g"', 'cook flatbread')

      state = storage.load
      reloaded_pantry = PantryChef::Pantry.from_h(state['pantry'])
      reloaded_book = PantryChef::RecipeBook.from_h(state['recipes'])

      expect(reloaded_pantry.get_item('flour')).to eq('quantity' => 300.0, 'unit' => 'g')
      expect(reloaded_book.all.map(&:name)).to eq(['flatbread'])
    end
  end
end