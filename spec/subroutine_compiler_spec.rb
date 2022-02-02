# frozen_string_literal: true

require 'tataru'

describe Tataru::SubroutineCompiler do
  it 'provides a label' do
    rrep = Tataru::Representations::ResourceRepresentation.new('cat', Tataru::BaseResourceDesc.new, {})
    sc = Tataru::SubroutineCompiler.new(rrep, false, :pet)

    expect(sc.label).to eq 'pet_cat'
  end

  it 'provides a call instruction' do
    rrep = Tataru::Representations::ResourceRepresentation.new('cat', Tataru::BaseResourceDesc.new, {})
    sc = Tataru::SubroutineCompiler.new(rrep, false, :pet)

    expect(sc.call_instruction).to eq(call: 'pet_cat')
  end

  it 'throws on unknown subroutine action' do
    rrep = Tataru::Representations::ResourceRepresentation.new('cat', Tataru::BaseResourceDesc.new, {})
    sc = Tataru::SubroutineCompiler.new(rrep, false, :pet)

    expect { sc.body_instructions }.to raise_error NoMethodError
  end

  it 'provides the standard body instructions' do
    rrep = Tataru::Representations::ResourceRepresentation.new('cat', Tataru::BaseResourceDesc.new, {})
    sc = Tataru::SubroutineCompiler.new(rrep, false, :pet)
    
    allow(sc).to receive(:pet_instructions) { [:make_pet] }

    expect(sc.body_instructions).to eq [
      :clear,
      :make_pet,
      :return
    ]
  end
end
