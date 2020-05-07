# frozen_string_literal: true

require 'tataru'

describe CheckDeleteInstruction do
  it 'reverses program counter if not completed' do
    mem = Memory.new
    instr = CheckDeleteInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:delete_complete?) { false }
    instr.run

    expect(mem.program_counter).to eq -1
  end

  it 'sets deleted' do
    mem = Memory.new
    instr = CheckDeleteInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:deleted] = []
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:delete_complete?) { true }
    allow_any_instance_of(BaseResourceDesc).to receive(:needs_remote_id?) { true }
    instr.run

    expect(mem.hash[:deleted]).to eq ['thing']
    expect(mem.hash[:remote_ids]).to eq({})
    expect(mem.program_counter).to eq 0
  end
end
