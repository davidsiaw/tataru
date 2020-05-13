# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::ValueInstruction do
  it 'set a value' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueInstruction.new('something')

    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: 'something')
  end

  it 'returns an error if no key' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueInstruction.new('something')

    mem.hash[:temp] = {}
    instr.memory = mem
    instr.run

    expect(mem.error).to eq 'No key set'
  end
end
