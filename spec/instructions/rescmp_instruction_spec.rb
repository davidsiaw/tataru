# frozen_string_literal: true

require 'tataru'

describe RescmpInstruction do
  # compares temp with rom properties
  # sets no_change, update, recreate

  it 'sets temp result to no_change if there are no changes' do
    mem = Memory.new
    instr = RescmpInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:mutable_fields) { [:prop] }

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
      resource_desc: 'BaseResourceDesc',
      'thing' => {
        prop: 'info'
      }
    }

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:result]).to eq :no_change
  end

  it 'sets temp result to update if there are changes to mutable' do
    mem = Memory.new
    instr = RescmpInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:mutable_fields) { [:prop] }

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
      resource_desc: 'BaseResourceDesc',
      'thing' => {
        prop: 'BBBB'
      }
    }

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:result]).to eq :update
  end

  it 'sets temp result to recreate if there are changes to immutable' do
    mem = Memory.new
    instr = RescmpInstruction.new

    allow_any_instance_of(BaseResourceDesc).to receive(:immutable_fields) { [:prop] }

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
      resource_desc: 'BaseResourceDesc',
      'thing' => {
        prop: 'BBNBB'
      }
    }

    instr.memory = mem
    instr.run

    expect(mem.hash[:temp][:result]).to eq :recreate
  end
end
