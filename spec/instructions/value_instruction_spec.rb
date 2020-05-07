# frozen_string_literal: true

require 'tataru'

describe ValueInstruction do
  it 'set a value' do
    mem = Memory.new
    instr = ValueInstruction.new('something')

    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: 'something')
  end

  it 'returns an error if no key' do
    mem = Memory.new
    instr = ValueInstruction.new('something')

    mem.hash[:temp] = {}
    instr.memory = mem
    instr.run

    expect(mem.error).to eq 'No key set'
  end
end
