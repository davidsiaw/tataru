# frozen_string_literal: true

module Tataru
  module Instructions
    # pushes the callstack and branches
    class CallInstruction < ImmediateModeInstruction
      def run
        labels = memory.hash[:labels]
        unless labels.key? @param
          memory.error = 'Label not found'
          return
        end

        memory.call_stack.push(memory.program_counter)
        memory.program_counter = labels[@param] - 1
      end
    end
  end
end
