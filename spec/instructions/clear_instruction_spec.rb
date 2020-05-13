# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::ClearInstruction do
  it 'clears temp' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ClearInstruction.new

    mem.hash[:temp] = { something: 'haha' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq({})
  end
end
