# frozen_string_literal: true

require 'tataru'

describe OutputRepresentation do
  it 'has a dependency on itself' do
    rr = OutputRepresentation.new('file', 'created_at')

    expect(rr.dependencies).to eq ['file']
  end
end
