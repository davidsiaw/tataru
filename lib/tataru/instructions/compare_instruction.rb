# frozen_string_literal: true

module Tataru
  module Instructions
    # compares whats in temp result to param
    class CompareInstruction < ImmediateModeInstruction
      def run
        memory.hash[:temp][:result] = if memory.hash[:temp][:result] == @param
                                        1
                                      else
                                        0
                                      end
      end
    end
  end
end
