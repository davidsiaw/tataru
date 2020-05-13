# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction that takes a parameter
    class ImmediateModeInstruction < Instruction
      def initialize(param)
        @param = param
      end
    end
  end
end
