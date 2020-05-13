# frozen_string_literal: true

require 'tataru'

describe Tataru::Flattener do
  it 'flattens literals' do
    f = Tataru::Flattener.new(Tataru::Representations::LiteralRepresentation.new('meow'))
    expect(f.flattened).to eq(
      top: {
        type: :literal,
        value: 'meow'
      }
    )
  end

  it 'flattens arrays' do
    f = Tataru::Flattener.new(Tataru::Representations::ArrayRepresentation.new(['meow']))
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
    f = Tataru::Flattener.new(Tataru::Representations::HashRepresentation.new({somefield: 'somevalue'}))
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
    f = Tataru::Flattener.new(Tataru::Representations::ResourceRepresentation.new('thing', Tataru::BaseResourceDesc.new, {}))
    expect(f.flattened).to eq(
      top: {
        type: :hash,
        references: {}
      }
    )
  end

  it 'flattens outputs' do
    f = Tataru::Flattener.new(Tataru::Representations::OutputRepresentation.new('employee', 'age'))
    expect(f.flattened).to eq(
      top: {
        type: :output,
        resource: 'employee',
        output: 'age'
      }
    )
  end

  it 'flattens resources that have properties' do
    f = Tataru::Flattener.new(Tataru::Representations::ResourceRepresentation.new(
      'thing',
      Tataru::BaseResourceDesc.new,
      { somefield: Tataru::Representations::LiteralRepresentation.new('somevalue') }
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
