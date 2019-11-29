# frozen_string_literal: true

module Tataru
  module Resources
    class RandomCodeResource < Tataru::Resource
      state :digit_count, :replace
      output :code

      def code
        'aaaaaa'
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

  context 'given two dependent requirements' do
    let(:req) do
      Tataru::Requirements.new do
        random_code 'mycode' do
          digit_count 6
        end
        file 'afile' do
          contents mycode.code
        end
      end
    end

    context 'given empty state' do
      let(:state) { Tataru::State.new }

      it 'has 4 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 4
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :wait_create
        expect(plan.instructions[1].id).to eq 'mycode'
        expect(plan.instructions[1].state).to eq(digit_count: 6)

        expect(plan.instructions[2].action).to eq :begin_create
        expect(plan.instructions[2].id).to eq 'afile'
        expect(plan.instructions[2].state[:contents].class).to eq Tataru::DoLater::MemberCallPlaceholder
        
        expect(plan.instructions[3].action).to eq :wait_create
        expect(plan.instructions[3].id).to eq 'afile'
        expect(plan.instructions[3].state[:contents].class).to eq Tataru::DoLater::MemberCallPlaceholder
      end
    end
  end

  context 'given two dependent requirements flipped' do
    let(:req) do
      Tataru::Requirements.new do
        file 'afile' do
          contents mycode.code
        end
        random_code 'mycode' do
          digit_count 6
        end
      end
    end

    context 'given empty state' do
      let(:state) { Tataru::State.new }

      it 'has 4 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 4
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :wait_create
        expect(plan.instructions[1].id).to eq 'mycode'
        expect(plan.instructions[1].state).to eq(digit_count: 6)

        expect(plan.instructions[2].action).to eq :begin_create
        expect(plan.instructions[2].id).to eq 'afile'
        expect(plan.instructions[2].state[:contents].class).to eq Tataru::DoLater::MemberCallPlaceholder
        
        expect(plan.instructions[3].action).to eq :wait_create
        expect(plan.instructions[3].id).to eq 'afile'
        expect(plan.instructions[3].state[:contents].class).to eq Tataru::DoLater::MemberCallPlaceholder
      end
    end
  end

  context 'not all state specified' do
    let(:req) {
      Tataru::Requirements.new do
        random_code 'mycode1' do
        end
      end
    }

    it 'throws error' do
      expect(req).to_not be_valid
      expect(req.errors).to match [ { missing_state: :digit_count } ]
    end

    it 'throws error out of planner' do
      state = Tataru::State.new
      expect { plan = Tataru::Planner.new(state, req) }.to(
        raise_error(Tataru::Rage::InvalidRequirement)
      )
    end
  end

  context 'given two independant requirements' do
    let(:req) do
      Tataru::Requirements.new do
        random_code 'mycode1' do
          digit_count 6
        end
        random_code 'mycode2' do
          digit_count 3
        end
      end
    end

    context 'given empty state' do
      let(:state) { Tataru::State.new }

      it 'has correct end state' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.end_state.getstate('mycode1', :digit_count)).to eq 6
        expect(plan.end_state.getstate('mycode2', :digit_count)).to eq 3
      end

      it 'has 4 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 4
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode1'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :begin_create
        expect(plan.instructions[1].id).to eq 'mycode2'
        expect(plan.instructions[1].state).to eq(digit_count: 3)

        expect(plan.instructions[2].action).to eq :wait_create
        expect(plan.instructions[2].id).to eq 'mycode1'
        expect(plan.instructions[2].state).to eq(digit_count: 6)

        expect(plan.instructions[3].action).to eq :wait_create
        expect(plan.instructions[3].id).to eq 'mycode2'
        expect(plan.instructions[3].state).to eq(digit_count: 3)
      end
    end

    context 'given one replaceable resource' do
      let(:state) { Tataru::State.new }

      before do
        state.putstate('mycode1', :digit_count, 6)
        state.putstate('mycode2', :digit_count, 6)
      end

      it 'has 4 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 4
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode2'
        expect(plan.instructions[0].state).to eq(digit_count: 3)

        expect(plan.instructions[1].action).to eq :wait_create
        expect(plan.instructions[1].id).to eq 'mycode2'
        expect(plan.instructions[1].state).to eq(digit_count: 3)

        expect(plan.instructions[2].action).to eq :begin_delete
        expect(plan.instructions[2].id).to eq 'mycode2'
        expect(plan.instructions[2].state).to eq(digit_count: 6)

        expect(plan.instructions[3].action).to eq :wait_delete
        expect(plan.instructions[3].id).to eq 'mycode2'
        expect(plan.instructions[3].state).to eq(digit_count: 6)
      end
    end
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
        expect(plan.instructions[0].action).to eq :begin_delete
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
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :wait_create
        expect(plan.instructions[1].id).to eq 'mycode'
        expect(plan.instructions[1].state).to eq(digit_count: 6)
      end

      it 'agrees with execution step' do
        plan = Tataru::Planner.new(state, req)

        instruction1 = plan.instructions[0]

        step1 = Tataru::ExecutionStep.new(state, instruction1)
        new_state, success = step1.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :create })
        expect(new_state.getstate('mycode', :digit_count)).to eq 6

        instruction2 = plan.instructions[1]

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:create_complete?) { false }
        )

        step2 = Tataru::ExecutionStep.new(state, instruction2)
        new_state, success = step2.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :create })
        expect(new_state.getstate('mycode', :digit_count)).to eq 6

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:create_complete?) { true }
        )

        step3 = Tataru::ExecutionStep.new(state, instruction2)
        new_state, success = step3.execute
        expect(new_state.waiting_list).to be_empty
        expect(new_state.getstate('mycode', :digit_count)).to eq 6
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

      it 'has 4 instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions.length).to eq 4
      end

      it 'has correct instructions' do
        plan = Tataru::Planner.new(state, req)
        expect(plan.instructions[0].action).to eq :begin_create
        expect(plan.instructions[0].id).to eq 'mycode'
        expect(plan.instructions[0].state).to eq(digit_count: 6)

        expect(plan.instructions[1].action).to eq :wait_create
        expect(plan.instructions[1].id).to eq 'mycode'
        expect(plan.instructions[1].state).to eq(digit_count: 6)

        expect(plan.instructions[2].action).to eq :begin_delete
        expect(plan.instructions[2].id).to eq 'mycode'
        expect(plan.instructions[2].state).to eq(digit_count: 7)

        expect(plan.instructions[3].action).to eq :wait_delete
        expect(plan.instructions[3].id).to eq 'mycode'
        expect(plan.instructions[3].state).to eq(digit_count: 7)
      end

      it 'agrees with execution step' do
        plan = Tataru::Planner.new(state, req)

        instruction1 = plan.instructions[0]

        step1 = Tataru::ExecutionStep.new(state, instruction1)
        new_state, success = step1.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :create })
        expect(new_state.getstate('mycode', :digit_count)).to eq 7
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq 6

        instruction2 = plan.instructions[1]

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:create_complete?) { false }
        )

        step2 = Tataru::ExecutionStep.new(state, instruction2)
        new_state, success = step2.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :create })
        expect(new_state.getstate('mycode', :digit_count)).to eq 7
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq 6

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:create_complete?) { true }
        )

        step3 = Tataru::ExecutionStep.new(state, instruction2)
        new_state, success = step3.execute
        expect(new_state.waiting_list).to be_empty
        expect(new_state.getstate('mycode', :digit_count)).to eq 7
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq 6


        instruction3 = plan.instructions[2]

        step4 = Tataru::ExecutionStep.new(state, instruction3)
        new_state, success = step4.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :delete })
        expect(new_state.getstate('mycode', :digit_count)).to eq 7
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq 6

        instruction4 = plan.instructions[3]

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:delete_complete?) { false }
        )

        step5 = Tataru::ExecutionStep.new(state, instruction4)
        new_state, success = step5.execute
        expect(new_state.waiting_list).to match({ 'mycode' => :delete })
        expect(new_state.getstate('mycode', :digit_count)).to eq 7
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq 6

        allow_any_instance_of(Tataru::Resources::RandomCodeResource).to(
          receive(:delete_complete?) { true }
        )

        step6 = Tataru::ExecutionStep.new(state, instruction4)
        new_state, success = step6.execute
        expect(new_state.waiting_list).to be_empty
        expect(new_state.getstate('mycode', :digit_count)).to eq 6
        expect(new_state.getstate('mycode', :digit_count, replacer: true)).to eq nil

        expect(plan.end_state.to_h).to match new_state.to_h
      end
    end
  end
end
