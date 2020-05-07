# frozen_string_literal: true

require 'tataru'

describe KeyInstruction do
  it 'set a key' do
    mem = Memory.new
    instr = KeyInstruction.new('meow')

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(_key: 'meow')
  end
end
