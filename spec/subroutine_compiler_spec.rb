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

  it 'throws on unknown subroutine action' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)

    expect { sc.body_instructions }.to raise_error NoMethodError
  end

  it 'provides the standard body instructions' do
    rrep = ResourceRepresentation.new('cat', BaseResourceDesc.new, {})
    sc = SubroutineCompiler.new(rrep, :pet)
    
    allow(sc).to receive(:pet_instructions) { [:make_pet] }

    expect(sc.body_instructions).to eq [
      :clear,
      :make_pet,
      :return
    ]
  end
end
