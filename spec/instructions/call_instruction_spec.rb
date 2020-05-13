# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::CallInstruction do
  it 'call an existing label' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::CallInstruction.new('function')

    mem.hash[:labels] = { 'function' => 10 }
    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 9
  end

  it 'sets error if no such label' do
    mem = Tataru::Memory.new
    mem.hash[:labels] = { }
    instr = Tataru::Instructions::CallInstruction.new('function')

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 0
    expect(mem.error).to eq 'Label not found'
  end
end
