# frozen_string_literal: true

require 'tataru'

describe HashRepresentation do
  it 'has no dependencies for empty array' do
    rep = HashRepresentation.new({})
    expect(rep.dependencies).to eq []
  end

  it 'has no dependencies for array with only literals' do
    rep = HashRepresentation.new({'greeting' => 'hi'})
    expect(rep.dependencies).to eq []
  end

  it 'has dependencies for each resource' do
    rr = ResourceRepresentation.new('file', BaseResourceDesc.new, {})
    rep = HashRepresentation.new(thing: rr)
    expect(rep.dependencies).to eq ['file']
  end

  it 'has dependencies for every resource' do
    rr1 = ResourceRepresentation.new('file1', BaseResourceDesc.new, {})
    rr2 = ResourceRepresentation.new('file2', BaseResourceDesc.new, {})
    rep = HashRepresentation.new(thing1: rr1, thing2: rr2, text: 'hello')
    
    expect(rep.dependencies).to eq ['file1', 'file2']
  end
end
