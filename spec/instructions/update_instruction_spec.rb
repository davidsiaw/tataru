# frozen_string_literal: true

require 'tataru'

describe UpdateInstruction do
  it 'calls update' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = UpdateInstruction.new('thing', resource_desc, { 'someprop' => 'somevalue' })

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    expect_any_instance_of(BaseResource).to receive(:update).with('someprop' => 'somevalue')
    instr.run(mem)
  end

  xit 'should throw error if an immutable prop is changed' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = UpdateInstruction.new('thing', resource_desc, { 'someprop' => 'somevalue' })

    allow(resource_desc).to receive(:immutable_fields) { ['someprop'] }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }

    expect { instr.run(mem) }.to raise_error 'immutable value changed'
  end
end
