# frozen_string_literal: true

require 'tataru'

describe Tataru::Representation do
  it 'has no dependencies' do
    rep = Tataru::Representations::LiteralRepresentation.new('hello')
    expect(rep.dependencies).to eq []
  end
end
