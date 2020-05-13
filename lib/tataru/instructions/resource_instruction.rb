# frozen_string_literal: true

module Tataru
  module Instructions
    # instructions that deal with resources
    class ResourceInstruction < Instruction
      expects :resource_name
      expects :resource_desc

      def desc
        Kernel.const_get(resource_desc).new
      end
    end
  end
end
