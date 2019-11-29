# frozen_string_literal: true

module Tataru
  module Resources
    class RandomCodeResource < Tataru::Resource
      state :digit_count, :replace

      def code
        'abcdef'
      end
    end

    class FileResource < Tataru::Resource
      state :contents, :update
    end
  end
end

RSpec.describe Tataru do
  it 'has a version number' do
    expect(Tataru::VERSION).not_to be nil
  end

  context 'given no requirement' do
    let(:req) do
      Tataru::Requirements.new do
      end
    end

    context 'given empty state' do
      let(:state) { Tataru::State.new }
      it 'has no instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to be_zero
      end
    end

    context 'given some state' do
      let(:state) { Tataru::State.new }

      before do
        state.putstate('mycode', :digit_count, 7)
      end

      it 'has 1 instruction' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 1
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :delete
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 7)
      end
    end
  end

  context 'given requirement with 1 object' do
    let(:req) do
      Tataru::Requirements.new do
        random_code 'mycode' do
          digit_count 6
        end
      end
    end

    context 'given empty state' do
      let(:state) { Tataru::State.new }
      it 'has correct end state' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.end_state.getstate('mycode', :digit_count)).to eq 6
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)
      end
    end

    context 'given same state' do
      let(:state) { Tataru::State.new }

      before do
        state.putstate('mycode', :digit_count, 6)
      end

      it 'has no instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to be_zero
      end
    end

    context 'given different state' do
      let(:state) { Tataru::State.new }

      before do
        state.putstate('mycode', :digit_count, 7)
      end

      it 'has correct end state' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.end_state.getstate('mycode', :digit_count)).to eq 6
      end

      it 'has 2 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 2
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :delete
        expect(plan.instructions[1].id).to eq 'mycode'
        expect(plan.instructions[1].state).to eq(digit_count: 7)
      end
    end
  end
end
