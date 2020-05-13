# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::KeyInstruction do
  it 'set a key' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::KeyInstruction.new('meow')

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(_key: 'meow')
  end
end
