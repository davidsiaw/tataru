# frozen_string_literal: true

require 'tataru'

describe Tataru::InstructionHash do
  it 'can be made' do
    im = Tataru::InstructionHash.new(init: {})

    expect(im.instruction_list).to be_empty
  end

  it 'makes init properly' do
    im = Tataru::InstructionHash.new(init: {
      remote_ids: {
        'thing' => 'abc'
      }
    }, instructions: [:init])

    expect(im.instruction_list[0]).to be_a(Tataru::Instructions::InitInstruction)
    expect(im.instruction_list[0].remote_ids).to eq('thing' => 'abc')
  end

  it 'adds instructions' do
    im = Tataru::InstructionHash.new(instructions:[
      :create
    ])

    expect(Tataru::Instructions::CreateInstruction).to receive(:new).and_call_original

    expect(im.instruction_list[0]).to be_a(Tataru::Instructions::CreateInstruction)
  end

  it 'add more instructions' do
    im = Tataru::InstructionHash.new(instructions:[
      :create,
      :delete
    ])

    expect(Tataru::Instructions::CreateInstruction).to receive(:new).and_call_original
    expect(Tataru::Instructions::DeleteInstruction).to receive(:new).and_call_original

    expect(im.instruction_list[0]).to be_a(Tataru::Instructions::CreateInstruction)
    expect(im.instruction_list[1]).to be_a(Tataru::Instructions::DeleteInstruction)
  end

  it 'adds immediate mode instructions' do
    im = Tataru::InstructionHash.new(instructions:[
      { key: 'name' }
    ])

    expect(Tataru::Instructions::KeyInstruction).to receive(:new).with('name').and_call_original

    expect(im.instruction_list[0]).to be_a(Tataru::Instructions::KeyInstruction)
  end

  it 'errors on unknown instruction' do
    im = Tataru::InstructionHash.new(instructions:[
      :unknown
    ])

    expect { im.instruction_list[0] }.to raise_error "Unknown instruction 'unknown'"
  end
end
