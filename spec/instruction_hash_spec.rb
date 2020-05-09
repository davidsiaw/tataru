# frozen_string_literal: true

require 'tataru'

describe InstructionHash do
  it 'can be made' do
    im = InstructionHash.new(init: {})

    expect(im.instruction_list).to be_empty
  end

  it 'makes init properly' do
    im = InstructionHash.new(init: {
      remote_ids: {
        'thing' => 'abc'
      }
    }, instructions: [:init])

    expect(im.instruction_list[0]).to be_a(InitInstruction)
    expect(im.instruction_list[0].remote_ids).to eq('thing' => 'abc')
  end

  it 'adds instructions' do
    im = InstructionHash.new(instructions:[
      :create
    ])

    expect(CreateInstruction).to receive(:new).and_call_original

    expect(im.instruction_list[0]).to be_a(CreateInstruction)
  end

  it 'add more instructions' do
    im = InstructionHash.new(instructions:[
      :create,
      :delete
    ])

    expect(CreateInstruction).to receive(:new).and_call_original
    expect(DeleteInstruction).to receive(:new).and_call_original

    expect(im.instruction_list[0]).to be_a(CreateInstruction)
    expect(im.instruction_list[1]).to be_a(DeleteInstruction)
  end

  it 'adds immediate mode instructions' do
    im = InstructionHash.new(instructions:[
      { key: 'name' }
    ])

    expect(KeyInstruction).to receive(:new).with('name').and_call_original

    expect(im.instruction_list[0]).to be_a(KeyInstruction)
  end

  it 'errors on unknown instruction' do
    im = InstructionHash.new(instructions:[
      :unknown
    ])

    expect { im.instruction_list[0] }.to raise_error "Unknown instruction 'unknown'"
  end
end
