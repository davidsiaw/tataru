# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::EndInstruction do
  it 'sets end to true' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::EndInstruction.new

    instr.memory = mem
    instr.run

    expect(mem.end).to eq true
  end
end
