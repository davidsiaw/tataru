# frozen_string_literal: true

module Tataru
  module Instructions
    # inverts the result
    class InvertInstruction < Instruction
      def run
        memory.hash[:temp][:result] = if (memory.hash[:temp][:result]).zero?
                                        1
                                      else
                                        0
                                      end
      end
    end
  end
end
