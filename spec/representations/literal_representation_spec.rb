# frozen_string_literal: true

require 'tataru'

describe Representation do
  it 'has no dependencies' do
    rep = LiteralRepresentation.new('hello')
    expect(rep.dependencies).to eq []
  end
end
