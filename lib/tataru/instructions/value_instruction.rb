# frozen_string_literal: true

module Tataru
  module Instructions
    # sets a hash entry based on whatever key was set
    class ValueInstruction < ImmediateModeInstruction
      def run
        return memory.error = 'No key set' unless memory.hash[:temp].key? :_key

        key = memory.hash[:temp].delete :_key
        memory.hash[:temp][key] = @param
      end
    end
  end
end
