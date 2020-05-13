# frozen_string_literal: true

module Tataru
  module Instructions
    # sets a key
    class KeyInstruction < ImmediateModeInstruction
      def run
        memory.hash[:temp][:_key] = @param
      end
    end
  end
end
