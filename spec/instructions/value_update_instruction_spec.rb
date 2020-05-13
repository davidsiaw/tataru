# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::ValueUpdateInstruction do
  it 'sets temp with update action of resource' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueUpdateInstruction.new('thething')

    mem.hash[:update_action] = {
      'thething' => :hello
    }

    mem.hash[:temp] = {}

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(
      result: :hello
    )
  end

  it 'throws if no such resource' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueUpdateInstruction.new('thething')

    mem.hash[:update_action] = {}

    mem.hash[:temp] = {}

    instr.memory = mem
    expect { instr.run }.to raise_error "No value set for 'thething'"
  end
end
