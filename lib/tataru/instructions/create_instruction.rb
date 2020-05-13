# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to create
    class CreateInstruction < ResourceInstruction
      expects :properties

      def run
        resource_class = desc.resource_class
        resource = resource_class.new(nil)
        resource.create(properties)

        return unless desc.needs_remote_id?

        memory.hash[:remote_ids][resource_name] = resource.remote_id
      end
    end
  end
end
