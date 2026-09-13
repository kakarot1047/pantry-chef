# frozen_string_literal: true

require 'tmpdir'

RSpec.describe PantryChef::Storage do
  subject(:storage) { described_class.new(path) }

  let(:path) { File.join(@directory, 'data', 'pantry_chef.json') }
  let(:pantry) { PantryChef::Pantry.new('sugar' => { 'quantity' => 200, 'unit' => 'g' }) }
  # RecipeBook has no serialization methods in the merged foundation yet.
  let(:recipe_book) { double('RecipeBook serialization interface', to_h: recipes) }
  let(:recipes) do
    { 'syrup' => { 'name' => 'syrup', 'servings' => 1,
                   'ingredients' => { 'sugar' => { 'quantity' => 100, 'unit' => 'g' } } } }
  end
  let(:error) { PantryChef::StorageError }

  around do |example|
    Dir.mktmpdir('pantry-chef-spec-') do |directory|
      @directory = directory
      example.run
    end
  end

  def write_source(content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  it 'returns independent empty states for a missing file without creating it' do
    state = storage.load
    expect(state).to eq('pantry' => {}, 'recipes' => {})
    state['pantry']['sugar'] = {}
    expect(storage.load).to eq('pantry' => {}, 'recipes' => {})
    expect(File.exist?(path)).to be(false)
  end

  it 'uses the documented default path relative to the launch directory' do
    expected = File.expand_path('data/pantry_chef.json')
    allow(File).to receive(:read).with(expected, encoding: 'UTF-8').and_raise(Errno::ENOENT)
    expect(described_class.new.load).to eq('pantry' => {}, 'recipes' => {})
  end

  it 'creates parent directories and writes valid JSON through public serialization methods' do
    expect(storage.save(pantry, recipe_book)).to be(true)
    expect(JSON.parse(File.read(path))).to eq('pantry' => pantry.to_h, 'recipes' => recipes)
    expect(Dir.children(File.dirname(path))).to eq(['pantry_chef.json'])
  end

  it 'loads existing JSON and preserves its source' do
    content = JSON.generate('pantry' => pantry.to_h, 'recipes' => recipes)
    write_source(content)
    expect(storage.load).to eq('pantry' => pantry.to_h, 'recipes' => recipes)
    expect(File.read(path)).to eq(content)
  end

  it 'round-trips pantry state through the public reconstruction interface' do
    storage.save(pantry, recipe_book)
    restored = PantryChef::Pantry.from_h(storage.load.fetch('pantry'))
    expect(restored.to_h).to eq(pantry.to_h)
    restored.consume('sugar', 50, 'g')
    expect(pantry.get_item('sugar')['quantity']).to eq(200)
    expect(storage.load['recipes']).to eq(recipes)
  end

  it 'replaces an existing save with a complete new state' do
    storage.save(pantry, recipe_book)
    pantry.update_item('sugar', 50)
    storage.save(pantry, recipe_book)
    expect(storage.load['pantry']['sugar']['quantity']).to eq(50)
    expect(Dir.children(File.dirname(path))).to eq(['pantry_chef.json'])
  end

  it 'round-trips Unicode ingredient names and fractional quantities' do
    pantry.add_item('jalapeño', 1.5, 'cups')
    storage.save(pantry, recipe_book)
    expect(storage.load['pantry']).to eq(pantry.to_h)
  end

  ['{broken', '', '{"pantry":'].each do |content|
    it "reports malformed JSON #{content.inspect} without replacing it" do
      write_source(content)
      expect { storage.load }.to raise_error(error, /Cannot load.*pantry_chef.json/)
      expect(File.read(path)).to eq(content)
    end
  end

  [nil, [], {}, { 'pantry' => [], 'recipes' => {} },
   { 'pantry' => {}, 'recipes' => [] },
   { 'pantry' => { 'sugar' => { 'quantity' => -1, 'unit' => 'g' } }, 'recipes' => {} }].each do |state|
    it "rejects invalid saved state #{state.inspect} and preserves the file" do
      content = JSON.generate(state)
      write_source(content)
      expect { storage.load }.to raise_error(error, /Cannot load/)
      expect(File.read(path)).to eq(content)
    end
  end

  it 'reports file read errors instead of silently substituting empty state' do
    allow(File).to receive(:read).with(path, encoding: 'UTF-8').and_raise(Errno::EACCES)
    expect { storage.load }.to raise_error(error, /Cannot load/)
  end

  it 'preserves the previous save if serialization fails' do
    storage.save(pantry, recipe_book)
    before = File.binread(path)
    allow(recipe_book).to receive(:to_h).and_return('invalid' => Float::NAN)
    expect { storage.save(pantry, recipe_book) }.to raise_error(error, /Cannot save/)
    expect(File.binread(path)).to eq(before)
  end

  it 'rejects the wrong recipe envelope before writing' do
    allow(recipe_book).to receive(:to_h).and_return([])
    expect { storage.save(pantry, recipe_book) }.to raise_error(error, /pantry and recipes objects/)
    expect(File.exist?(path)).to be(false)
  end

  it 'preserves the previous save and cleans temporary files if replacement fails' do
    storage.save(pantry, recipe_book)
    before = File.binread(path)
    allow(File).to receive(:rename).and_raise(Errno::EACCES)
    pantry.update_item('sugar', 50)
    expect { storage.save(pantry, recipe_book) }.to raise_error(error, /Cannot save/)
    expect(File.binread(path)).to eq(before)
    expect(Dir.children(File.dirname(path))).to eq(['pantry_chef.json'])
  end

  it 'cleans a partially written temporary file after a disk failure' do
    storage.save(pantry, recipe_book)
    before = File.binread(path)
    allow(Tempfile).to receive(:create).and_wrap_original do |original, *args, &block|
      original.call(*args) do |file|
        allow(file).to receive(:write) do
          file.syswrite('partial')
          raise Errno::ENOSPC
        end
        block.call(file)
      end
    end
    expect { storage.save(pantry, recipe_book) }.to raise_error(error, /Cannot save/)
    expect(File.binread(path)).to eq(before)
    expect(Dir.children(File.dirname(path))).to eq(['pantry_chef.json'])
  end

  it 'reports a parent directory creation failure' do
    allow(FileUtils).to receive(:mkdir_p).and_raise(Errno::EACCES)
    expect { storage.save(pantry, recipe_book) }.to raise_error(error, /Cannot save/)
    expect(File.exist?(path)).to be(false)
  end
end
