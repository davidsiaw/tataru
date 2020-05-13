# frozen_string_literal: true

module Tataru
  module Instructions
    # ends the program
    class EndInstruction < Instruction
      def run
        memory.end = true
      end
    end
  end
end
