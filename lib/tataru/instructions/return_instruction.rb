# frozen_string_literal: true

module Tataru
  module Instructions
    # pops the callstack and goes back
    class ReturnInstruction < Instruction
      def run
        return memory.error = 'At bottom of stack' if memory.call_stack.count.zero?

        memory.program_counter = memory.call_stack.pop
      end
    end
  end
end
