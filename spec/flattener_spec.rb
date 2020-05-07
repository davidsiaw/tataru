# frozen_string_literal: true

require 'tataru'

describe Flattener do
  it 'flattens literals' do
    f = Flattener.new(LiteralRepresentation.new('meow'))
    expect(f.flattened).to eq(
      top: {
        type: :literal,
        value: 'meow'
      }
    )
  end

  it 'flattens arrays' do
    f = Flattener.new(ArrayRepresentation.new(['meow']))
    expect(f.flattened).to eq(
      top: {
        type: :array,
        references: {
          0 => :top_0
        }
      },
      top_0: {
        type: :literal,
        value: 'meow'
      }
    )
  end

  it 'flattens hashes' do
    f = Flattener.new(HashRepresentation.new({somefield: 'somevalue'}))
    expect(f.flattened).to eq(
      top: {
        type: :hash,
        references: {
          somefield: :top_somefield
        }
      },
      top_somefield: {
        type: :literal,
        value: 'somevalue'
      }
    )
  end

  it 'flattens resources' do
    f = Flattener.new(ResourceRepresentation.new('thing', BaseResourceDesc.new, {}))
    expect(f.flattened).to eq(
      top: {
        type: :hash,
        references: {}
      }
    )
  end

  it 'flattens outputs' do
    f = Flattener.new(OutputRepresentation.new('employee', 'age'))
    expect(f.flattened).to eq(
      top: {
        type: :output,
        resource: 'employee',
        output: 'age'
      }
    )
  end

  it 'flattens resources that have properties' do
    f = Flattener.new(ResourceRepresentation.new(
      'thing',
      BaseResourceDesc.new,
      { somefield: LiteralRepresentation.new('somevalue') }
    ))
    expect(f.flattened).to eq(
      top: {
        type: :hash,
        references: {
          somefield: :top_somefield
        }
      },
      top_somefield: {
        type: :literal,
        value: 'somevalue'
      }
    )
  end
end
