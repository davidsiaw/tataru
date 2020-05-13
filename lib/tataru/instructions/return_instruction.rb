# frozen_string_literal: true

module Tataru
  module Instructions
    # pops the callstack and goes back
    class ReturnInstruction < Instruction
      def run
        if memory.call_stack.count.zero?
          return memory.error = 'At bottom of stack'
    end

        memory.program_counter = memory.call_stack.pop
      end
    end
  end
end
