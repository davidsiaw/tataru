# frozen_string_literal: true

require 'tataru'

describe CheckCreateInstruction do
  it 'reverses program counter if not completed' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CheckCreateInstruction.new('thing', resource_desc)

    expect(mem.program_counter).to eq 0

    mem.hash[:remote_ids] = { 'thing' => 'hello' }

    allow_any_instance_of(BaseResource).to receive(:create_complete?) { false }
    instr.run(mem)

    expect(mem.program_counter).to eq -1
  end

  it 'sets outputs' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CheckCreateInstruction.new('thing', resource_desc)

    expect(mem.program_counter).to eq 0

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:outputs] = {}

    allow_any_instance_of(BaseResource).to receive(:create_complete?) { true }
    allow_any_instance_of(BaseResource).to receive(:outputs) { { something: 'a'} }
    allow(resource_desc).to receive(:output_fields) { [:something] }
    instr.run(mem)

    expect(mem.hash[:outputs]['thing']).to eq(something: 'a')
    expect(mem.program_counter).to eq 0
  end
end
