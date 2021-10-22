# frozen_string_literal: true

module Tataru
  module Instructions
    # read properties of resource
    class ReadInstruction < ResourceInstruction
      def run
        results = resource.read(fields)
        info = {}
        fields.each do |k|
          info[k] = results[k]
        end
        memory.hash[:temp][resource_name] = info
      end

      def resource_class
        @resource_class ||= desc.resource_class
      end

      def resource
        @resource ||= resource_class.new(memory.hash[:remote_ids][resource_name])
      end

      def fields
        @fields ||= desc.immutable_fields + desc.mutable_fields
      end
    end
  end
end
