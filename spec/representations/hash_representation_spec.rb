# frozen_string_literal: true

require 'tataru'

describe Tataru::Representations::HashRepresentation do
  it 'has no dependencies for empty array' do
    rep = Tataru::Representations::HashRepresentation.new({})
    expect(rep.dependencies).to eq []
  end

  it 'has no dependencies for array with only literals' do
    rep = Tataru::Representations::HashRepresentation.new({'greeting' => 'hi'})
    expect(rep.dependencies).to eq []
  end

  it 'has dependencies for each resource' do
    rr = Tataru::Representations::ResourceRepresentation.new('file', Tataru::BaseResourceDesc.new, {})
    rep = Tataru::Representations::HashRepresentation.new(thing: rr)
    expect(rep.dependencies).to eq ['file']
  end

  it 'has dependencies for every resource' do
    rr1 = Tataru::Representations::ResourceRepresentation.new('file1', Tataru::BaseResourceDesc.new, {})
    rr2 = Tataru::Representations::ResourceRepresentation.new('file2', Tataru::BaseResourceDesc.new, {})
    rep = Tataru::Representations::HashRepresentation.new(thing1: rr1, thing2: rr2, text: 'hello')
    
    expect(rep.dependencies).to eq ['file1', 'file2']
  end
end
