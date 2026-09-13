# frozen_string_literal: true

require 'open3'
require 'rbconfig'
require 'tmpdir'

RSpec.describe 'Pantry management and persistence workflows' do
  around do |example|
    Dir.mktmpdir('pantry-chef-workflow-') do |directory|
      @path = File.join(directory, 'state.json')
      example.run
    end
  end

  it 'lets a home cook manage stock and retrieve it in a fresh Ruby process' do
    pantry = PantryChef::Pantry.new
    pantry.add_item('Sugar', 200, 'g')
    pantry.add_item('sugar', 50, 'g')
    pantry.update_item('SUGAR', 100)
    pantry.add_item('water', 300, 'ml')
    pantry.remove_item('water')
    PantryChef::Storage.new(@path).save(pantry, {})

    # This uses the public domain API; the teammate-owned terminal CLI is still deferred.
    program = <<~RUBY
      require 'storage'
      state = PantryChef::Storage.new(ARGV.fetch(0)).load
      pantry = PantryChef::Pantry.from_h(state.fetch('pantry'))
      puts JSON.generate(pantry.items)
    RUBY
    library = File.expand_path('../../lib', __dir__)
    output, errors, status = Open3.capture3(RbConfig.ruby, '-I', library, '-e', program, @path)

    expect(status.success?).to be(true), errors
    expect(JSON.parse(output)).to eq('sugar' => { 'quantity' => 100, 'unit' => 'g' })
  end

  it 'keeps valid inventory after rejected changes and a subsequent save' do
    pantry = PantryChef::Pantry.new
    pantry.add_item('sugar', 200, 'g')
    storage = PantryChef::Storage.new(@path)
    storage.save(pantry, {})

    expect { pantry.add_item('sugar', -5, 'g') }.to raise_error(PantryChef::ValidationError)
    expect { pantry.consume('sugar', 201, 'g') }.to raise_error(PantryChef::ValidationError)
    expect { pantry.add_item('sugar', 1, 'kg') }.to raise_error(PantryChef::ValidationError)
    storage.save(pantry, {})

    restored = PantryChef::Pantry.from_h(PantryChef::Storage.new(@path).load.fetch('pantry'))
    expect(restored.get_item('SUGAR')).to eq('quantity' => 200, 'unit' => 'g')
  end
end
