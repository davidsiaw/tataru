# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to create
    class CreateInstruction < ResourceInstruction
      expects :properties

      def run
        resource.create(properties)

        check!
        memory.hash[:remote_ids][resource_name] = resource.remote_id
      end

      private

      def check!
        return unless desc.needs_remote_id?
        raise 'Resource expects a remote id but does not give one' if resource.remote_id.nil?
        raise 'Remote id already set' unless memory.hash[:remote_ids][resource_name].nil?
      end

      def resource_class
        @resource_class ||= desc.resource_class
      end

      def resource
        @resource ||= resource_class.new(nil)
      end
    end
  end
end
