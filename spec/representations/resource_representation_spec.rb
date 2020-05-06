# frozen_string_literal: true

require 'tataru'

describe ResourceRepresentation do
  it 'has a dependency on itself' do
    rr = ResourceRepresentation.new('file', BaseResourceDesc.new, {})

    expect(rr.dependencies).to eq ['file']
  end

  it 'releases outputs' do
    desc = BaseResourceDesc.new
    rr = ResourceRepresentation.new('file', desc, {})

    allow(desc).to receive(:output_fields) { [:created_at] }

    expect(rr.created_at).to be_a(OutputRepresentation)
    expect(rr.created_at.resource_name).to eq 'file'
    expect(rr.created_at.output_field_name).to eq :created_at
  end

  it 'throws error when no such output' do
    desc = BaseResourceDesc.new
    rr = ResourceRepresentation.new('file', desc, {})

    allow(desc).to receive(:output_fields) { [:created_at] }

    expect { rr.updated_at }.to raise_error NoMethodError
  end
end
