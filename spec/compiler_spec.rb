# frozen_string_literal: true

require 'tataru'

describe Compiler do
  it 'outputs the correct default format' do
    dsl = TopDsl.new(ResourceTypePool.new)
    compiler = Compiler.new(dsl)
    expect(compiler.instr_hash).to eq(
      init: {
        labels: {},
        remote_ids: {},
        rom: {}
      },
      instructions: [:init, :end]
    )
  end

  it 'outputs'
end
