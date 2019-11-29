# frozen_string_literal: true

module Tataru
  # An execution step
  class ExecutionStep
    def initialize(state, instruction)
      @state = state
      @instruction = instruction
      @instances = {}
    end

    def id
      @instruction.id
    end

    def rf
      @instruction.requirements.resource_finder
    end

    def type_of_id
      @instruction.requirements.type(id)
    end

    def class_of_id
      rf.resource_named(type_of_id)
    end

    def instance_of_id
      @instances[id] ||= class_of_id.new
    end

    def execute
      return execute_begin! if @instruction.action.to_s.start_with?('begin_')

      execute_wait!
    end

    def overall_action
      @instruction.action.to_s.split('_')[1].to_sym
    end

    def execute_begin!
      instance_of_id.send(@instruction.action, @state)
      [send(:"begin_#{overall_action}"), true]
    end

    def begin_create
      new_state = @state.clone
      replacer = true
      replacer = false if new_state[id].nil?

      @instruction.state.each do |name, value|
        new_state.putstate(id, name, value, replacer: replacer)
      end
      new_state.waiting_on(id, overall_action)
      new_state
    end

    def begin_delete
      begin_update
    end

    def begin_update
      new_state = @state.clone
      new_state.waiting_on(id, overall_action)
      new_state
    end

    def execute_wait!
      new_state = @state.clone
      success = instance_of_id.send(:"#{overall_action}_complete?", @state)
      if success
        new_state.no_longer_waiting(id)
        new_state.replace(id) if overall_action == :delete
      end
      [new_state, success]
    end
  end
end
