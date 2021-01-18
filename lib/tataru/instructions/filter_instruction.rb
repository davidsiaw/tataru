# frozen_string_literal: true

module Tataru
  module Instructions
    # filters out any fields that are the same as rom
    class FilterInstruction < ResourceInstruction
      expects :properties

      def run
        filter!
      end

      private

      def filter!
        current = memory.hash[:temp][resource_name]
        desired = memory.hash[:temp][:properties]

        memory.hash[:temp][:properties] = filter(current, desired)
      end

      def filter(current, desired)
        result = {}
        desc.mutable_fields.each do |field|
          result[field] = desired[field]
        end
        desc.immutable_fields.each do |field|
          result[field] = desired[field] if current[field] != desired[field]
        end
        result
      end
    end
  end
end
