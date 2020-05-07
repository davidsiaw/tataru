# frozen_string_literal: true

require 'tataru'

describe Instruction do
  it 'can be made' do
    Instruction.new
  end

  it 'checks parameters' do
    instr = Class.new(Instruction)
    instr.class_eval do
      expects :param1
    end

    mem = Memory.new
    mem.hash[:temp] = {}

    expect { instr.new.execute(mem) }.to raise_error 'required param param1 not found'
  end

  it 'allows execution to occur if param exists' do
    instr = Class.new(Instruction)
    instr.class_eval do
      expects :param1
    end

    mem = Memory.new
    mem.hash[:temp] = { param1: 'hello' }

    instruction = instr.new
    expect(instruction).to receive(:run)

    instruction.execute(mem)
  end
end
