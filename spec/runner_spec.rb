# frozen_string_literal: true

require 'tataru'

describe Runner do
  it 'can be made' do
    runner = Runner.new([])
  end

  it 'returns ended when ended' do
    runner = Runner.new([])
    expect(runner).to be_ended
  end

  it 'returns not ended when not ended' do
    runner = Runner.new([Instruction.new])
    expect(runner).to_not be_ended
  end

  it 'runs instructions in order' do
    inst1 = Instruction.new
    inst2 = Instruction.new

    runner = Runner.new([
      inst1, inst2
    ])

    expect(inst1).to receive(:run)
    runner.run_next

    expect(inst2).to receive(:run)
    runner.run_next
  end
end
