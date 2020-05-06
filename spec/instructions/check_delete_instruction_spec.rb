# frozen_string_literal: true

require 'tataru'

describe CheckDeleteInstruction do
  it 'reverses program counter if not completed' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CheckDeleteInstruction.new('thing', resource_desc)

    expect(mem.program_counter).to eq 0

    mem.hash[:remote_ids] = { 'thing' => 'hello' }

    allow_any_instance_of(BaseResource).to receive(:delete_complete?) { false }
    instr.run(mem)

    expect(mem.program_counter).to eq -1
  end

  it 'sets deleted' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CheckDeleteInstruction.new('thing', resource_desc)

    expect(mem.program_counter).to eq 0

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:deleted] = []

    allow_any_instance_of(BaseResource).to receive(:delete_complete?) { true }
    allow(resource_desc).to receive(:needs_remote_id?) { true }
    instr.run(mem)

    expect(mem.hash[:deleted]).to eq ['thing']
    expect(mem.hash[:remote_ids]).to eq({})
    expect(mem.program_counter).to eq 0
  end
end
