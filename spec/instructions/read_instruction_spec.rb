# frozen_string_literal: true

require 'tataru'

describe ReadInstruction do
  it 'sets hashes' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = ReadInstruction.new('thing', resource_desc, [:prop])

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    mem.hash[:temp] = {}

    expect_any_instance_of(BaseResource).to receive(:read).with([:prop]) { {:prop => 'info'} }
    instr.run(mem)

    expect(mem.hash[:temp]['thing'][:prop]).to eq 'info'
  end
end
