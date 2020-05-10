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

  it 'returns an output representation when given an output' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:immutable_fields) { [:filename] }

    desc = BaseResourceDesc.new
    rr = ResourceRepresentation.new('other_resource', desc, {})
    allow(desc).to receive(:output_fields) { [:created_at] }

    dsl = ResourceDsl.new('somefile', resource_desc)
    dsl.filename rr.created_at

    expect(dsl.representation).to be_a ResourceRepresentation
    expect(dsl.representation.properties[:filename]).to be_a OutputRepresentation
    expect(dsl.representation.properties[:filename].resource_name).to eq 'other_resource'
    expect(dsl.representation.properties[:filename].output_field_name).to eq :created_at
  end

  it 'returns an output representation of remote ID' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:immutable_fields) { [:filename] }


    desc = BaseResourceDesc.new
    rr = ResourceRepresentation.new('other_resource', desc, {})
    allow(desc).to receive(:output_fields) { [:created_at] }


    dsl = ResourceDsl.new('somefile', resource_desc)
    dsl.filename rr

    expect(dsl.representation).to be_a ResourceRepresentation
    expect(dsl.representation.properties[:filename]).to be_a OutputRepresentation
    expect(dsl.representation.properties[:filename].resource_name).to eq 'other_resource'
    expect(dsl.representation.properties[:filename].output_field_name).to eq :remote_id
  end

  it 'throws error if nonexistent field' do
    resource_desc = BaseResourceDesc.new
    allow(resource_desc).to receive(:immutable_fields) { [:filename] }

    dsl = ResourceDsl.new('somefile', resource_desc)
    expect { dsl.age 'thing' }.to raise_error NoMethodError
  end
end
