# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::UpdateInstruction do
  it 'calls update' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::UpdateInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      properties: { 'someprop' => 'somevalue' }
    }

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    expect_any_instance_of(Tataru::BaseResource).to receive(:update).with('someprop' => 'somevalue')
    
    instr.run
  end

  it 'should throw error if an immutable prop is changed' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::UpdateInstruction.new

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:immutable_fields) { ['someprop'] }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      properties: { 'someprop' => 'somevalue' }
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    expect { instr.run }.to raise_error 'immutable value changed'
  end
end
