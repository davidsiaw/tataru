# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::CheckUpdateInstruction do
  it 'reverses program counter if not completed' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::CheckUpdateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    allow_any_instance_of(Tataru::BaseResource).to receive(:update_complete?) { false }
    instr.run

    expect(mem.program_counter).to eq -1
  end

  it 'sets outputs' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::CheckUpdateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:outputs] = {}
    instr.memory = mem

    allow_any_instance_of(Tataru::BaseResource).to receive(:update_complete?) { true }
    allow_any_instance_of(Tataru::BaseResource).to receive(:outputs) { { something: 'a2'} }
    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:output_fields) { [:something] }
    instr.run

    expect(mem.hash[:outputs]['thing']).to eq(something: 'a2')
    expect(mem.program_counter).to eq 0
  end

  it 'throws if output is not a hash' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::CheckUpdateInstruction.new

    expect(mem.program_counter).to eq 0

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'Tataru::BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:outputs] = {}
    instr.memory = mem

    allow_any_instance_of(Tataru::BaseResource).to receive(:update_complete?) { true }
    allow_any_instance_of(Tataru::BaseResource).to receive(:outputs) { 'a2' }
    allow_any_instance_of(Tataru::BaseResourceDesc).to receive(:output_fields) { [:something] }
    expect { instr.run }.to raise_error "Output for 'thing' is not a hash"
  end
end
