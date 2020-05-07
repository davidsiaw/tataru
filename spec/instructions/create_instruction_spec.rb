# frozen_string_literal: true

require 'tataru'

describe CreateInstruction do
  it 'sets remote id when needs remote id is true' do
    mem = Memory.new
    instr = CreateInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:needs_remote_id?) { true }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'abc' })
    allow_any_instance_of(BaseResource).to receive(:remote_id) { 'someid' }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      properties: { someprop: 'abc' }
    }
    mem.hash[:remote_ids] = {}
    instr.memory = mem
    instr.run

    expect(mem.hash[:remote_ids]['thing']).to eq 'someid'
  end

  it 'does not set remote id if does not need remote id' do
    mem = Memory.new
    instr = CreateInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:needs_remote_id?) { false }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'def' })

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      properties: { someprop: 'def' }
    }
    mem.hash[:remote_ids] = {}
    instr.memory = mem

    instr.run
  end

  xit 'throws error if remote_id already set' do
    mem = Memory.new
    instr = CreateInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:needs_remote_id?) { true }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'abc' })
    allow_any_instance_of(BaseResource).to receive(:remote_id) { 'someid' }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      properties: { someprop: 'abc' }
    }
    mem.hash[:remote_ids] = { 'thing' => 'def' }
    instr.memory = mem

    expect { instr.run }.to raise_error
  end
end
