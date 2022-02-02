# frozen_string_literal: true

module Tataru
  module Instructions
    # throws the exception specified if the result is 0
    class AssertInstruction < ImmediateModeInstruction
      def run
        return if memory.hash[:temp][:result] == 1

        ex_name = "::Tataru::Exceptions::#{@param.to_s.camelize}"
        raise Kernel.const_get(ex_name)
      end
    end
  end
end
