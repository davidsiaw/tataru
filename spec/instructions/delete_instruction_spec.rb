# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::DeleteInstruction do
  it 'calls delete on the resource' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::DeleteInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    expect_any_instance_of(Tataru::BaseResource).to receive(:delete)
    instr.run
  end
end
