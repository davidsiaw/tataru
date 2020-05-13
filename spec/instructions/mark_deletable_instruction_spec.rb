# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::MarkDeletableInstruction do
  it 'set a resource as deletable' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::MarkDeletableInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:remote_ids]).to eq('_deletable_thing' => 'hello')
  end
end
