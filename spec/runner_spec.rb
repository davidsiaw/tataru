# frozen_string_literal: true

require 'tataru'

describe Tataru::Runner do
  it 'can be made' do
    runner = Tataru::Runner.new([])
  end

  it 'returns ended when ended' do
    runner = Tataru::Runner.new([])
    expect(runner).to be_ended
  end

  it 'returns not ended when not ended' do
    runner = Tataru::Runner.new([Tataru::Instruction.new])
    expect(runner).to_not be_ended
  end

  it 'returns ended when ended' do
    runner = Tataru::Runner.new([Tataru::Instruction.new])
    runner.memory.end = true
    expect(runner).to be_ended
  end

  it 'returns ended when errored' do
    runner = Tataru::Runner.new([Tataru::Instruction.new])
    runner.memory.error = 'Something'
    expect(runner).to be_ended
  end

  it 'sets memory error if instruction throws' do
    inst1 = Tataru::Instruction.new
    allow(inst1).to receive(:run) { raise 'hello' }

    runner = Tataru::Runner.new([inst1])
    runner.run_next

    expect(runner).to be_ended
    expect(runner.memory.error).to be_a RuntimeError
  end

  it 'runs instructions in order' do
    inst1 = Tataru::Instruction.new
    inst2 = Tataru::Instruction.new

    runner = Tataru::Runner.new([
      inst1, inst2
    ])

    expect(inst1).to receive(:run)
    runner.run_next

    expect(inst2).to receive(:run)
    runner.run_next
  end

  it 'records resource instructions' do
    inst1cls = Class.new(Tataru::Instructions::ResourceInstruction)
    stub_const('TestInstruction', inst1cls)
    inst1 = inst1cls.new


    runner = Tataru::Runner.new([
      inst1
    ])

    runner.memory.hash[:temp][:resource_name] = 'abcd'
    runner.run_next

    expect(runner.oplog).to eq [
      {
        operation: 'TEST',
        resource: 'abcd'
      }
    ]
  end

  it 'ignores tataru instruction namespace' do
    inst1cls = Class.new(Tataru::Instructions::ResourceInstruction)
    stub_const('Tataru::Instructions::TestInstruction', inst1cls)
    inst1 = inst1cls.new


    runner = Tataru::Runner.new([
      inst1
    ])

    runner.memory.hash[:temp][:resource_name] = 'defg'
    runner.run_next

    expect(runner.oplog).to eq [
      {
        operation: 'TEST',
        resource: 'defg'
      }
    ]
  end
end
