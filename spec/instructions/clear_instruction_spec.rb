# frozen_string_literal: true

require 'tataru'

describe ClearInstruction do
  it 'clears temp' do
    mem = Memory.new
    instr = ClearInstruction.new

    mem.hash[:temp] = { something: 'haha' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq({})
  end
end
