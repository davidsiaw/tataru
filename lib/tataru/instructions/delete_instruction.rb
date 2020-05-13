# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to delete
    class DeleteInstruction < ResourceInstruction
      def run
        resource_class = desc.resource_class
        resource = resource_class.new(memory.hash[:remote_ids][resource_name])
        resource.delete
      end
    end
  end
end
