# frozen_string_literal: true

require 'tataru'

describe CheckUpdateInstruction do
  it 'reverses program counter if not completed' do
    mem = Memory.new
    instr = CheckUpdateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:update_complete?) { false }
    instr.run

    expect(mem.program_counter).to eq -1
  end

  it 'sets outputs' do
    mem = Memory.new
    instr = CheckUpdateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:outputs] = {}
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:update_complete?) { true }
    allow_any_instance_of(BaseResource).to receive(:outputs) { { something: 'a2'} }
    allow_any_instance_of(BaseResourceDesc).to receive(:output_fields) { [:something] }
    instr.run

    expect(mem.hash[:outputs]['thing']).to eq(something: 'a2')
    expect(mem.program_counter).to eq 0
  end
end
