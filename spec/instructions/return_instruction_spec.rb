# frozen_string_literal: true

require 'tataru'

describe ReturnInstruction do
  it 'return to top of stack' do
    mem = Memory.new
    instr = ReturnInstruction.new

    mem.call_stack = [1, 2, 3]
    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 3
  end

  it 'sets error if no more stack' do
    mem = Memory.new
    mem.call_stack = []
    instr = ReturnInstruction.new

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 0
    expect(mem.error).to eq 'At bottom of stack'
  end
end
