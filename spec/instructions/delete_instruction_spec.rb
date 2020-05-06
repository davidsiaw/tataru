# frozen_string_literal: true

require 'tataru'

describe DeleteInstruction do
  it 'sets hashes' do
    mem = Memory.new
    resource_desc = BaseResourceDesc.new
    instr = DeleteInstruction.new('thing', resource_desc)

    mem.hash[:remote_ids] = { 'thing' => 'hello' }
    expect_any_instance_of(BaseResource).to receive(:delete)
    instr.run(mem)
  end
end
