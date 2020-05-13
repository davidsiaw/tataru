# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::InitInstruction do
  it 'sets hashes' do
    instr = Tataru::Instructions::InitInstruction.new
    mem = Tataru::Memory.new
    instr.memory = mem
    instr.run
    expect(mem.hash.key? :remote_ids).to eq true
    expect(mem.hash.key? :outputs).to eq true
    expect(mem.hash.key? :labels).to eq true
    expect(mem.hash.key? :deleted).to eq true
  end
end
