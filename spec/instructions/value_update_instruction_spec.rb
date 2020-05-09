# frozen_string_literal: true

require 'tataru'

describe ValueUpdateInstruction do
  it 'sets temp with update action of resource' do
    mem = Memory.new
    instr = ValueUpdateInstruction.new('thething')

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
    mem = Memory.new
    instr = ValueUpdateInstruction.new('thething')

    mem.hash[:update_action] = {}

    mem.hash[:temp] = {}

    instr.memory = mem
    expect { instr.run }.to raise_error "No value set for 'thething'"
  end
end
