# frozen_string_literal: true

require 'tataru'

describe ReadInstruction do
  it 'sets hashes' do
    mem = Memory.new
    instr = ReadInstruction.new

    mem.hash[:temp] = {
      resource_name: 'thing',
      resource_desc: 'BaseResourceDesc'
    }
    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    instr.memory = mem

    expect_any_instance_of(BaseResourceDesc).to receive(:immutable_fields) { [:prop1] }
    expect_any_instance_of(BaseResourceDesc).to receive(:mutable_fields) { [:prop2] }

    expect_any_instance_of(BaseResource).to receive(:read).with([:prop1, :prop2]) do
      {
        prop1: 'info',
        prop2: '1234',
        extra: 'notseen'
      }
    end
    instr.run

    expect(mem.hash[:temp]['thing']).to eq(
      prop1: 'info',
      prop2: '1234'
    )
  end
end
