# frozen_string_literal: true

require 'tataru'

describe GotoIfInstruction do
  it 'branches if result is non zero' do
    mem = Memory.new
    instr = GotoIfInstruction.new(5)

    mem.hash[:temp] = { result: 1 }

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 4
  end

  it 'does nothing if result is zero' do
    mem = Memory.new
    instr = GotoIfInstruction.new(6)

    mem.hash[:temp] = { result: 0 }

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 0
  end

  it 'goes to label if param is label' do
    mem = Memory.new
    instr = GotoIfInstruction.new('function')

    mem.hash[:labels] = { 'function' => 10 }
    mem.hash[:temp] = { result: 1 }

    instr.memory = mem
    instr.run

    expect(mem.program_counter).to eq 9
  end
end
