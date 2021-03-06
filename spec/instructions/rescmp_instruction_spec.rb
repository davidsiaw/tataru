# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::RescmpInstruction do
  # compares temp with rom properties
  # sets no_change, update, recreate

  it 'sets temp result to no_change if there are no changes' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::RescmpInstruction.new

    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) { [:prop] }

    mem.hash[:rom] = {
      'thing' => {
        type: :hash,
        references: {
          :prop => 'literal'
        }
      },
      'literal' => {
        type: :literal,
        value: 'info'
      }
    }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      'thing' => {
        prop: 'info'
      }
    }

    mem.hash[:update_action] = {}

    instr.memory = mem
    instr.run

    expect(mem.hash[:update_action]['thing']).to eq :no_change
  end

  it 'sets temp result to modify if there are changes to mutable' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::RescmpInstruction.new

    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:mutable_fields) { [:prop] }

    mem.hash[:rom] = {
      'thing' => {
        type: :hash,
        references: {
          :prop => 'literal'
        }
      },
      'literal' => {
        type: :literal,
        value: 'AAAA'
      }
    }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      'thing' => {
        prop: 'BBBB'
      }
    }

    mem.hash[:update_action] = {}

    instr.memory = mem
    instr.run

    expect(mem.hash[:update_action]['thing']).to eq :modify
  end

  it 'sets temp result to recreate if there are changes to immutable' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::RescmpInstruction.new

    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:immutable_fields) { [:prop] }

    mem.hash[:rom] = {
      'thing' => {
        type: :hash,
        references: {
          :prop => 'literal'
        }
      },
      'literal' => {
        type: :literal,
        value: 'AAAAA'
      }
    }

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc',
      'thing' => {
        prop: 'BBNBB'
      }
    }

    mem.hash[:update_action] = {}

    instr.memory = mem
    instr.run

    expect(mem.hash[:update_action]['thing']).to eq :recreate
  end
end
