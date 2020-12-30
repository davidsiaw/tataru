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
        raise 'Resource expects a remote id but does not give one' if resource.remote_id.nil?
        raise 'Remote id already set' unless memory.hash[:remote_ids][resource_name].nil?

        memory.hash[:remote_ids][resource_name] = resource.remote_id
      end
    end
  end
end
