# frozen_string_literal: true

module Tataru
  module Instructions
    # clears temp memory
    class ClearInstruction < Instruction
      def run
        memory.hash[:temp] = {}
      end
    end
  end
end
