# frozen_string_literal: true

require 'tataru'

describe SubroutineCompiler do
  it 'provides a label' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)

    expect(sc.label).to eq 'pet_cat'
  end

  it 'provides a call instruction' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)

    expect(sc.call_instruction).to eq(call: 'pet_cat')
  end

  it 'provides the standard body instructions' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)

    expect(sc.body_instructions).to eq [
      :clear,
      {key: :resource_name},
      {value: 'cat'},
      {key: :resource_desc},
      {value: 'BaseResourceDesc'},
      :pet,
      :return
    ]
  end

  it 'provides extra instructions if available' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)

    allow(sc).to receive(:pet_extra_instructions) { [:feed] }

    expect(sc.body_instructions).to eq [
      :clear,
      {key: :resource_name},
      {value: 'cat'},
      {key: :resource_desc},
      {value: 'BaseResourceDesc'},
      :feed,
      :pet,
      :return
    ]
  end
end
