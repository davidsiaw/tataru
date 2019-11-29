# frozen_string_literal: true

module Tataru
  # An instruction
  class Instruction
    attr_reader :action, :id, :state, :requirements

    def initialize(action, id, state, requirements)
      @action = action
      @id = id
      @state = state
      @requirements = requirements
    end
  end
end
