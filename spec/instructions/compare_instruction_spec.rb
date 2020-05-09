# frozen_string_literal: true

require 'tataru'

describe CompareInstruction do
  it 'sets to 1 if equal' do
    mem = Memory.new
    instr = CompareInstruction.new('abc')

    mem.hash[:temp] = { result: 'abc' }

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:result]).to eq 1
  end

  it 'sets to 0 if not equal' do
    mem = Memory.new
    instr = CompareInstruction.new('def')

    mem.hash[:temp] = { result: 'abc' }

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:result]).to eq 0
  end
end
