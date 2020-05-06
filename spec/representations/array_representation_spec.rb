# frozen_string_literal: true

require 'tataru'

describe ArrayRepresentation do
  it 'has no dependencies for empty array' do
    rep = ArrayRepresentation.new([])
    expect(rep.dependencies).to eq []
  end

  it 'has no dependencies for array with only literals' do
    rep = ArrayRepresentation.new(['hi'])
    expect(rep.dependencies).to eq []
  end

  it 'has dependencies for each resource' do
    rr = ResourceRepresentation.new('file', BaseResourceDesc.new, {})
    rep = ArrayRepresentation.new([rr])
    expect(rep.dependencies).to eq ['file']
  end

  it 'has dependencies for every resource' do
    rr1 = ResourceRepresentation.new('file1', BaseResourceDesc.new, {})
    rr2 = ResourceRepresentation.new('file2', BaseResourceDesc.new, {})
    rep = ArrayRepresentation.new([rr1, rr2, 'awd'])

    expect(rep.dependencies).to eq ['file1', 'file2']
  end
end
