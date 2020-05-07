# frozen_string_literal: true

require 'tataru'

describe ReadInstruction do
  it 'sets hashes' do
    mem = Memory.new
    instr = ReadInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc',
      property_names: [:prop]
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    expect_any_instance_of(BaseResource).to receive(:read).with([:prop]) { {:prop => 'info'} }
    instr.run

    expect(mem.hash[:temp]['thing'][:prop]).to eq 'info'
  end
end
