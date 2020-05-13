# frozen_string_literal: true

require 'tataru'

describe Tataru::InitHashCompiler do
  it 'resolves references' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    ihc = Tataru::InitHashCompiler.new(dsl)

    refs = {
      aaa: 'top_thing',
      bbb: 'top'
    }

    expect(ihc.resolved_references('resname', refs)).to eq(
      aaa: 'resname_thing',
      bbb: 'resname'
    )
  end

  it 'generates an init hash' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    ihc = Tataru::InitHashCompiler.new(dsl)

    expect(ihc.generate_init_hash).to eq(rom: {}, remote_ids: {})
  end

  it 'generates hashes for each resource' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    ihc = Tataru::InitHashCompiler.new(dsl)

    rr = Tataru::Representations::ResourceRepresentation.new('file', Tataru::BaseResourceDesc.new, {})
    allow(dsl).to receive(:resources) { { 'file1' => rr } }

    allow_any_instance_of(Tataru::Flattener).to receive(:flattened) do
      {
        'abc' => {
          type: :teststuff
        }
      }
    end

    expect(ihc.generate_init_hash).to eq(
      rom: {
        'abc' => {
          type: :teststuff
        }
      },
      remote_ids: {}
    )
  end

  it 'generates hashes for each resource with references' do
    dsl = Tataru::TopDsl.new(Tataru::ResourceTypePool.new)
    ihc = Tataru::InitHashCompiler.new(dsl)

    rr = Tataru::Representations::ResourceRepresentation.new('file', Tataru::BaseResourceDesc.new, {
      aaa: Tataru::Representations::LiteralRepresentation.new('meow')
    })
    allow(dsl).to receive(:resources) { { 'file1' => rr } }

    allow_any_instance_of(Tataru::Flattener).to receive(:flattened) do
      {
        'abc' => {
          type: :teststuff,
          references: {
            thing: 'top_stuff'
          }
        }
      }
    end

    expect(ihc.generate_init_hash).to eq(
      rom: {
        'abc' => {
          type: :teststuff,
          references: {
            thing: 'file1_stuff'
          }
        }
      },
      remote_ids: {}
    )
  end
end
