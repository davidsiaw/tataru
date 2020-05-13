# frozen_string_literal: true

require 'tataru'

describe Tataru::Instructions::ValueRomInstruction do
  it 'returns an error if no key' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {}
    mem.hash[:temp] = {}
    instr.memory = mem
    instr.run

    expect(mem.error).to eq 'No key set'
  end

  it 'returns an error if no such thing' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {}
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    expect { instr.run }.to raise_error 'Not found'
  end

  it 'sets a literal' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {
      'something' => {
        type: :literal,
        value: 'somevalue'
      }
    }
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: 'somevalue')
  end

  it 'sets an array' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {
      'something' => {
        type: :array,
        references: {
          0 => 'a',
          1 => 'b'
        }
      },
      'a' => {
        type: :literal,
        value: 'meow'
      },
      'b' => {
        type: :literal,
        value: 'woof'
      }
    }
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: ['meow', 'woof'])
  end

  it 'sets a hash' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {
      'something' => {
        type: :hash,
        references: {
          'x' => 'aaa',
          'y' => 'bbbb'
        }
      },
      'aaa' => {
        type: :literal,
        value: 100
      },
      'bbbb' => {
        type: :literal,
        value: 200
      }
    }
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: {
      'x' => 100,
      'y' => 200
    })
  end

  it 'sets an output' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:outputs] = {
      'someresource' => {
        name: 'somename'
      }
    }

    mem.hash[:rom] = {
      'something' => {
        type: :output,
        resource: 'someresource',
        output: :name
      }
    }
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: 'somename')
  end

  it 'sets inner values' do
    mem = Tataru::Memory.new
    instr = Tataru::Instructions::ValueRomInstruction.new('something')

    mem.hash[:rom] = {
      'something' => {
        type: :hash,
        references: {
          'x' => 'literal',
          'y' => 'array'
        }
      },
      'literal' => {
        type: :literal,
        value: 'something'
      },
      'array' => {
        type: :array,
        references: {
          0 => 'value1',
          1 => 'value2'
        }
      },
      'value1' => {
        type: :literal,
        value: 'v1'
      },
      'value2' => {
        type: :literal,
        value: 'v2'
      }
    }
    mem.hash[:temp] = { _key: :somefield }
    instr.memory = mem
    instr.run

    expect(mem.hash[:temp]).to eq(somefield: {
      'x' => 'something',
      'y' => ['v1', 'v2']
    })
  end

end
