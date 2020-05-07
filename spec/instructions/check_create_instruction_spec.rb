# frozen_string_literal: true

require 'tataru'

describe CheckCreateInstruction do
  it 'reverses program counter if not completed' do
    mem = Memory.new
    instr = CheckCreateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:create_complete?) { false }
    instr.run

    expect(mem.program_counter).to eq -1
  end

  it 'sets outputs' do
    mem = Memory.new
    instr = CheckCreateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:outputs] = {}
    instr.memory = mem

    allow_any_instance_of(BaseResource).to receive(:create_complete?) { true }
    allow_any_instance_of(BaseResource).to receive(:outputs) { { something: 'a'} }
    allow_any_instance_of(BaseResourceDesc).to receive(:output_fields) { [:something] }
    instr.run

    expect(mem.hash[:outputs]['thing']).to eq(something: 'a')
    expect(mem.program_counter).to eq 0
  end
end
