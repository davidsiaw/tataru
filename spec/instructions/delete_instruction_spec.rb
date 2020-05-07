# frozen_string_literal: true

require 'tataru'

describe DeleteInstruction do
  it 'sets hashes' do
    mem = Memory.new
    instr = DeleteInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    
    expect_any_instance_of(BaseResource).to receive(:delete)
    instr.run
  end
end
