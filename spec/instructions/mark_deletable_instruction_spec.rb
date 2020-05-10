# frozen_string_literal: true

require 'tataru'

describe MarkDeletableInstruction do
  it 'set a resource as deletable' do
    mem = Memory.new
    instr = MarkDeletableInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:remote_ids]).to eq('_deletable_thing' => 'hello')
  end
end
