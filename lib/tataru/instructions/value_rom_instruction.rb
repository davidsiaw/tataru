# frozen_string_literal: true

module Tataru
  module Instructions
    # sets a hash entry and resolves from rom what was set
    class ValueRomInstruction < ImmediateModeInstruction
      include RomReader

      def run
        return memory.error = 'No key set' unless memory.hash[:temp].key? :_key

        key = memory.hash[:temp].delete :_key
        memory.hash[:temp][key] = resolve(rom_object)
      end

      def rom_object
        raise 'Not found' unless rom.key? @param

        rom[@param]
      end
    end
  end
end
