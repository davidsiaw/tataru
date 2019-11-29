# frozen_string_literal: true

module Tataru
  # Requirements list
  class Requirements
    attr_reader :resource_finder, :errors

    def initialize(resource_finder = DefaultResourceFinder.new, &block)
      dsl = RequirementsDSL.new(resource_finder)
      dsl.instance_exec(&block)
      @errors = dsl.errors
      @reqs = dsl.resource_list
      @resource_finder = resource_finder
    end

    def dep_tree
      @reqs.map { |k, v| [k, v[:dependencies]] }.to_h
    end

    def end_state
      state = State.new
      @reqs.each do |id, info|
        info[:state].each do |state_name, state_value|
          state.putstate(id, state_name, state_value)
        end
      end
      state
    end

    def exist?(id)
      @reqs.key? id
    end

    def type(id)
      @reqs[id][:type]
    end

    def valid?
      errors.length.zero?
    end

    def compare(id, current_state)
      rclass = @resource_finder.resource_named(type(id))
      resdef = rclass.new
      changed = false
      replace = false

      current_state.each do |state_name, current_value|
        next if current_value == @reqs[id][:state][state_name]

        changed = true
        replace ||= resdef.send(:"#{state_name}_change_action") == :replace
      end

      [changed, replace]
    end

    def action(id, current_state)
      changed, replace = compare(id, current_state)

      return :nothing unless changed
      return :update unless replace

      :replace
    end
  end
end
