# frozen_string_literal: true

require 'tataru'

describe InstructionHash do
  let(:pool) do
    pool = ResourceTypePool.new
    pool.add_resource_desc(:base, BaseResourceDesc)
    pool
  end

  it 'can be made' do
    im = InstructionHash.new(pool, init: {})

    expect(im.instruction_list[0]).to be_a(InitInstruction)
  end

  it 'makes init properly' do
    im = InstructionHash.new(pool, init: {
      remote_ids: {
        'thing' => 'abc'
      }
    })

    expect(im.instruction_list[0]).to be_a(InitInstruction)
    expect(im.instruction_list[0].remote_ids).to eq('thing' => 'abc')
  end

  it 'adds instructions' do
    im = InstructionHash.new(pool, instructions:[
      {
        type: :resource,
        action: :create,
        resourcetype: :base,
        name: 'something',
        args: {
          'somefield' => 'somevalue'
        }
      }
    ])

    expect(CreateInstruction).to receive(:new).with(
      'something',
      BaseResourceDesc,
      {
        'somefield' => 'somevalue'
      }).and_call_original

    expect(im.instruction_list[1]).to be_a(CreateInstruction)
  end

  it 'errors on unknown instruction' do
    im = InstructionHash.new(pool, instructions:[
      {
        type: :awd,
        action: :create,
      }
    ])

    expect { im.instruction_list[0] }.to raise_error "unknown instruction"
  end
end
