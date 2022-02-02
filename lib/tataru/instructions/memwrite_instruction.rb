# frozen_string_literal: true

module Tataru
  module Instructions
    # writes the value into the key and superkey
    class MemwriteInstruction < ImmediateModeInstruction
      expects :superkey
      expects :key

      def run
        memory.hash[superkey][key] = @param
      end
    end
  end
end
