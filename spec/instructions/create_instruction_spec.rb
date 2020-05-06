# frozen_string_literal: true

require 'tataru'

describe CreateInstruction do
  it 'sets remote id when needs remote id is true' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CreateInstruction.new('thing', resource_desc, { someprop: 'abc' })

    expect(resource_desc).to receive(:needs_remote_id?) { true }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'abc' })
    allow_any_instance_of(BaseResource).to receive(:remote_id) { 'someid' }

    mem.hash[:remote_ids] = {}
    instr.run(mem)

    expect(mem.hash[:remote_ids]['thing']).to eq 'someid'
  end

  it 'does not set remote id if does not need remote id' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CreateInstruction.new('thing', resource_desc, { someprop: 'def' })

    expect(resource_desc).to receive(:needs_remote_id?) { false }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'def' })

    mem.hash[:remote_ids] = {}

    instr.run(mem)
  end

  xit 'throws error if remote_id already set' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = CreateInstruction.new('thing', resource_desc, { someprop: 'abc' })

    expect(resource_desc).to receive(:needs_remote_id?) { true }
    expect_any_instance_of(BaseResource).to receive(:create).with({ someprop: 'abc' })
    allow_any_instance_of(BaseResource).to receive(:remote_id) { 'someid' }

    mem.hash[:remote_ids] = { 'thing' => 'def' }

    expect { instr.run(mem) }.to raise_error
  end
end
