# frozen_string_literal: true

module Tataru
  module Instructions
    # sets temp result
    class ValueUpdateInstruction < ImmediateModeInstruction
      def run
        raise "No value set for '#{@param}'" unless memory.hash[:update_action].key? @param

        memory.hash[:temp] = {
          result: memory.hash[:update_action][@param]
        }
      end
    end
  end
end
