# frozen_string_literal: true

RSpec.describe PantryChef::Pantry do
  subject(:pantry) { described_class.new }

  let(:error) { PantryChef::ValidationError }

  it 'starts empty and returns nil for an unknown ingredient' do
    expect(pantry.items).to eq({})
    expect(pantry.get_item('sugar')).to be_nil
  end

  it 'adds quantities and normalizes names and units' do
    pantry.add_item(' Sugar ', '200', ' G ')
    expect(pantry.get_item('SUGAR')).to eq('quantity' => 200, 'unit' => 'g')
    pantry.add_item('sugar', 50, 'g')
    expect(pantry.get_item('sugar')['quantity']).to eq(250)
  end

  it 'lists ingredients in alphabetical order' do
    pantry.add_item('water', 300, 'ml')
    pantry.add_item('flour', 500, 'g')
    expect(pantry.items.keys).to eq(%w[flour water])
  end

  it 'sets an absolute quantity, preserving the unit unless explicitly replaced' do
    pantry.add_item('sugar', 200, 'g')
    pantry.update_item('SUGAR', 100)
    expect(pantry.get_item('sugar')).to eq('quantity' => 100, 'unit' => 'g')
    pantry.update_item('sugar', 0.1, ' KG ')
    expect(pantry.get_item('sugar')).to eq('quantity' => 0.1, 'unit' => 'kg')
  end

  it 'removes an item without affecting other ingredients' do
    pantry.add_item('sugar', 200, 'g')
    pantry.add_item('water', 100, 'ml')
    pantry.remove_item(' SUGAR ')
    expect(pantry.items.keys).to eq(['water'])
  end

  [nil, '', '  ', 42].each do |value|
    it "rejects invalid names and units #{value.inspect} without changing state" do
      pantry.add_item('sugar', 200, 'g')
      before = pantry.to_h
      expect { pantry.add_item(value, 1, 'g') }.to raise_error(error, /name/)
      expect { pantry.add_item('flour', 1, value) }.to raise_error(error, /Unit/)
      expect { pantry.update_item('sugar', 1, value) }.to raise_error(error, /Unit/) unless value.nil?
      expect(pantry.to_h).to eq(before)
    end
  end

  [nil, true, [], {}, 'abc', '', '2 g', -5, 0, '0', '-1', Float::NAN,
   Float::INFINITY, -Float::INFINITY, 'NaN', 'Infinity', '1e999', Complex(1, 2)].each do |value|
    it "rejects invalid quantity #{value.inspect} in every operation without mutation" do
      pantry.add_item('sugar', 200, 'g')
      before = pantry.to_h
      expect { pantry.add_item('sugar', value, 'g') }.to raise_error(error, /Quantity/)
      expect { pantry.update_item('sugar', value) }.to raise_error(error, /Quantity/)
      expect { pantry.consume('sugar', value, 'g') }.to raise_error(error, /Quantity/)
      expect { pantry.sufficient?('sugar', value, 'g') }.to raise_error(error, /Quantity/)
      expect(pantry.to_h).to eq(before)
    end
  end

  it 'rejects a sum that would overflow to infinity' do
    pantry.add_item('sugar', Float::MAX, 'g')
    expect { pantry.add_item('sugar', Float::MAX, 'g') }.to raise_error(error, /finite/)
    expect(pantry.get_item('sugar')['quantity']).to eq(Float::MAX)
  end

  it 'rejects mismatched addition and consumption without changing inventory' do
    pantry.add_item('sugar', 200, 'g')
    before = pantry.to_h
    expect { pantry.add_item('sugar', 1, 'kg') }.to raise_error(error, /Unit mismatch/)
    expect { pantry.consume('sugar', 1, 'kg') }.to raise_error(error, /Unit mismatch/)
    expect(pantry.to_h).to eq(before)
  end

  it 'reports missing ingredients on update, removal, and consumption' do
    expect { pantry.update_item('sugar', 1) }.to raise_error(error, /not found: sugar/)
    expect { pantry.remove_item('sugar') }.to raise_error(error, /not found: sugar/)
    expect { pantry.consume('sugar', 1, 'g') }.to raise_error(error, /not found: sugar/)
    expect(pantry.to_h).to eq({})
  end

  it 'checks availability without modifying stock' do
    pantry.add_item('sugar', 200, 'g')
    expect(pantry.sufficient?(' SUGAR ', 200, ' G ')).to be(true)
    expect(pantry.sufficient?('sugar', 201, 'g')).to be(false)
    expect(pantry.sufficient?('sugar', 1, 'kg')).to be(false)
    expect(pantry.sufficient?('flour', 1, 'g')).to be(false)
    expect(pantry.get_item('sugar')['quantity']).to eq(200)
  end

  it 'consumes stock and removes an ingredient when exhausted' do
    pantry.add_item('sugar', 200, 'g')
    pantry.consume('SUGAR', 50, 'G')
    expect(pantry.get_item('sugar')['quantity']).to eq(150)
    pantry.consume('sugar', 150, 'g')
    expect(pantry.get_item('sugar')).to be_nil
  end

  it 'rejects insufficient consumption without changing state' do
    pantry.add_item('sugar', 200, 'g')
    expect { pantry.consume('sugar', 201, 'g') }.to raise_error(error, /Insufficient/)
    expect(pantry.get_item('sugar')['quantity']).to eq(200)
  end

  it 'does not expose mutable state through inputs, lookups, or serialization' do
    name = +'sugar'
    unit = +'g'
    added = pantry.add_item(name, 200, unit)
    name.replace('flour')
    unit.replace('kg')
    added['quantity'] = -1
    [pantry.get_item('sugar'), pantry.items['sugar'], pantry.to_h['sugar']].each do |item|
      item['quantity'] = -1
      item['unit'].replace('kg')
    end
    pantry.items.clear
    expect(pantry.to_h).to eq('sugar' => { 'quantity' => 200, 'unit' => 'g' })
  end

  it 'reconstructs a pantry independently from a serialized hash' do
    source = { ' Sugar ' => { 'quantity' => 200, 'unit' => +'G' } }
    restored = described_class.from_h(source)
    source[' Sugar ']['unit'].replace('kg')
    source.clear
    expect(restored.to_h).to eq('sugar' => { 'quantity' => 200, 'unit' => 'g' })
  end

  [nil, [], { 'sugar' => nil }, { 'sugar' => {} },
   { 'sugar' => { 'quantity' => -1, 'unit' => 'g' } }].each do |source|
    it "rejects malformed serialized inventory #{source.inspect}" do
      expect { described_class.from_h(source) }.to raise_error(error)
    end
  end

  it 'rejects ambiguous normalized names when restoring saved inventory' do
    item = { 'quantity' => 1, 'unit' => 'g' }
    expect { described_class.from_h('Sugar' => item, 'sugar' => item) }.to raise_error(error, /Duplicate/)
  end
end
