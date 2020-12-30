# frozen_string_literal: true

module Tataru
  module Instructions
    # update a resource
    class UpdateInstruction < ResourceInstruction
      expects :properties

      def run
        resource_class = desc.resource_class
        resource = resource_class.new(memory.hash[:remote_ids][resource_name])
        raise 'immutable value changed' unless (desc.immutable_fields & properties.keys).empty?

        resource.update(properties)
      end
    end
  end
end
