# frozen_string_literal: true

module Tataru
  module Instructions
    # puts remote id up for deletion
    class MarkDeletableInstruction < ResourceInstruction
      def run
        remote_id = memory.hash[:remote_ids].delete(resource_name)
        memory.hash[:remote_ids]["_deletable_#{resource_name}"] = remote_id
      end
    end
  end
end
