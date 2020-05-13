# frozen_string_literal: true

require 'tataru'

describe Tataru::Representations::OutputRepresentation do
  it 'has a dependency on itself' do
    rr = Tataru::Representations::OutputRepresentation.new('file', 'created_at')

    expect(rr.dependencies).to eq ['file']
  end
end
