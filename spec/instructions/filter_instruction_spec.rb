# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::FilterInstruction do
  # removes any properties that are the same from the properties hash

  it 'does not filter anything if hash is different value' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::FilterInstruction.new

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) do
      []
    end

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:immutable_fields) do
      %i[someprop]
    end

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      properties: { someprop: 'diffvalue' },
      'thing' => { someprop: 'somevalue' }
    }

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    
    instr.run

    expect(mem.hash[:temp][:properties]).to eq(someprop: 'diffvalue')
  end

  it 'removes properties that are same as properties hash' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::FilterInstruction.new

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) do
      []
    end

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:immutable_fields) do
      %i[someprop]
    end

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      properties: { someprop: 'samevalue' },
      'thing' => { someprop: 'samevalue' }
    }

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:properties]).to eq({})
  end

  it 'does not remove mutable properties that are same as properties hash' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::FilterInstruction.new

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) do
      %i[someprop]
    end

    expect_any_instance_of(Tataru::BaseResourceDesc).to receive(:immutable_fields) do
      []
    end

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      properties: { someprop: 'samevalue' },
      'thing' => { someprop: 'samevalue' }
    }

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:properties]).to eq(someprop: 'samevalue')
  end
end
