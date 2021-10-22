# frozen_string_literal: true

module Tataru
  module Instructions
    # General checking class
    class CheckInstruction < ResourceInstruction
      def initialize(check_type)
        @check_type = check_type
        super()
      end

      def run
        resource_class = desc.resource_class
        resource = resource_class.new(memory.hash[:remote_ids][resource_name])

        if resource.send(:"#{@check_type}_complete?")
          after_complete
        else
          # repeat this instruction until its done
          memory.program_counter -= 1
        end
      end

      def after_complete(_memory); end
    end
  end
end
