# frozen_string_literal: true

require 'tataru'

describe UpdateInstruction do
  it 'calls update' do
    mem = Memory.new
    instr = UpdateInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      properties: { 'someprop' => 'somevalue' }
    }

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    expect_any_instance_of(BaseResource).to receive(:update).with('someprop' => 'somevalue')
    
    instr.run
  end

  xit 'should throw error if an immutable prop is changed' do
    mem = Memory.new
    instr = UpdateInstruction.new

    expect_any_instance_of(BaseResourceDesc).to receive(:immutable_fields) { ['someprop'] }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      properties: { 'someprop' => 'somevalue' }
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    expect { instr.run }.to raise_error 'immutable value changed'
  end
end
