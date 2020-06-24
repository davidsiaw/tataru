# frozen_string_literal: true

module Tataru
  module Instructions
    # goto if temp result is non zero
    class GotoIfInstruction < ImmediateModeInstruction
      def run
        return if memory.hash[:temp][:result].zero?

        memory.program_counter = if @param.is_a? Integer
                                   @param - 1
                                 else
                                   label_branch!
                                 end
      end

      def label_branch!
        raise "Label '#{@param}' not found" unless memory.hash[:labels]&.key?(@param)

        memory.hash[:labels][@param] - 1
      end
    end
  end
end
