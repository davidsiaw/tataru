# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to check create
    class CheckCreateInstruction < CheckInstruction
      def initialize
        super :create
      end

      def after_complete
        memory.hash[:outputs][resource_name] = outputs
      end

      def outputs
        return {} unless desc.output_fields.count

        resource_class = desc.resource_class
        resource = resource_class.new(memory.hash[:remote_ids][resource_name])
        o = resource.outputs
        raise "Output for '#{resource_name}' is not a hash" unless o.is_a? Hash

        resource.outputs
      end
    end
  end
end
