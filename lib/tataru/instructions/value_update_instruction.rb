# frozen_string_literal: true

module Tataru
  module Instructions
    # sets temp result
    class ValueUpdateInstruction < ImmediateModeInstruction
      def run
        unless memory.hash[:update_action].key? @param
          raise "No value set for '#{@param}'"
        end

        memory.hash[:temp] = {
          result: memory.hash[:update_action][@param]
        }
      end
    end
  end
end
