# frozen_string_literal: true

require 'tataru'

describe CallInstruction do
  it 'call an existing label' do
    mem = Memory.new
    instr = CallInstruction.new('function')

    mem.hash[:labels] = { 'function' => 10 }
    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 9
  end

  it 'sets error if no such label' do
    mem = Memory.new
    mem.hash[:labels] = { }
    instr = CallInstruction.new('function')

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 0
    expect(mem.error).to eq 'Label not found'
  end
end
