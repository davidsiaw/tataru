# frozen_string_literal: true

require 'tataru'

describe EndInstruction do
  it 'sets end to true' do
    mem = Memory.new
    instr = EndInstruction.new

    instr.memory = mem
    instr.run

    expect(mem.end).to eq true
  end
end
