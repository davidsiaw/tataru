# frozen_string_literal: true

require 'tataru'

describe Tataru::Representations::ArrayRepresentation do
  it 'has no dependencies for empty array' do
    rep = Tataru::Representations::ArrayRepresentation.new([])
    expect(rep.dependencies).to eq []
  end

  it 'has no dependencies for array with only literals' do
    rep = Tataru::Representations::ArrayRepresentation.new(['hi'])
    expect(rep.dependencies).to eq []
  end

  it 'has dependencies for each resource' do
    rr = Tataru::Representations::ResourceRepresentation.new('file', Tataru::BaseResourceDesc.new, {})
    rep = Tataru::Representations::ArrayRepresentation.new([rr])
    expect(rep.dependencies).to eq ['file']
  end

  it 'has dependencies for every resource' do
    rr1 = Tataru::Representations::ResourceRepresentation.new('file1', Tataru::BaseResourceDesc.new, {})
    rr2 = Tataru::Representations::ResourceRepresentation.new('file2', Tataru::BaseResourceDesc.new, {})
    rep = Tataru::Representations::ArrayRepresentation.new([rr1, rr2, 'awd'])

    expect(rep.dependencies).to eq ['file1', 'file2']
  end
end
