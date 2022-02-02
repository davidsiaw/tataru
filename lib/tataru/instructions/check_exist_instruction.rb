# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to check existence
    class CheckExistInstruction < ResourceInstruction
      def resource
        resource_class = desc.resource_class
        resource_class.new(memory.hash[:remote_ids][resource_name])
      end

      def run
        memory.hash[:temp][:result] = true
        return unless desc.needs_remote_id?

        memory.hash[:temp][:result] = resource.exist? ? true : false
      end
    end
  end
end
