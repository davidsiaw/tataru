# frozen_string_literal: true

module Tataru
  module Instructions
    # check that delete is completed
    class CheckDeleteInstruction < CheckInstruction
      def initialize
        super :delete
      end

      def after_complete
        memory.hash[:deleted] << resource_name

        return unless desc.needs_remote_id?

        memory.hash[:remote_ids].delete(resource_name)
      end
    end
  end
end
