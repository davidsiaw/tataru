# frozen_string_literal: true

module Tataru
  # An instruction
  class Instruction
    attr_reader :action, :id, :state

    def initialize(action, id, state = {})
      @action = action
      @id = id
      @state = state
    end
  end
end
