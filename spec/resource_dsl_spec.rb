# frozen_string_literal: true

require 'tataru'

describe ResourceDsl do
  it 'validates mutable fields' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:mutable_fields) { [:filename] }

    dsl = ResourceDsl.new('somefile', resource_desc)
    dsl.filename 'thing'

    expect(dsl.representation).to be_a ResourceRepresentation
    expect(dsl.representation.properties[:filename]).to be_a LiteralRepresentation
  end

  it 'validates immutable fields' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:immutable_fields) { [:filename] }

    dsl = ResourceDsl.new('somefile', resource_desc)
    dsl.filename 'thing'

    expect(dsl.representation).to be_a ResourceRepresentation
    expect(dsl.representation.properties[:filename]).to be_a LiteralRepresentation
  end

  it 'throws error if nonexistent field' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:immutable_fields) { [:filename] }

    dsl = ResourceDsl.new('somefile', resource_desc)
    expect { dsl.age 'thing' }.to raise_error NoMethodError
  end
end
