# frozen_string_literal: true

module Tataru
  # subroutines for replacing resources
  module RecreateSubroutines
    def recreate_instructions
      deletion_routine = [
        *load_resource_instructions,
        :mark_deletable
      ]
      unless desc.delete_at_end?
        deletion_routine = [
          *delete_instructions,
          *check_delete_instructions
        ]
      end
      [
        *deletion_routine,
        *create_instructions
      ]
    end

    def recreate_check_instructions
      [
        *check_create_instructions
      ]
    end

    def recreate_commit_instructions
      return [] unless desc.delete_at_end?

      [
        { key: :resource_name },
        { value: "_deletable_#{@rrep.name}" },
        { key: :resource_desc },
        { value: @rrep.desc.class.name },
        :delete
      ]
    end

    def recreate_finish_instructions
      return [] unless desc.delete_at_end?

      [
        { key: :resource_name },
        { value: "_deletable_#{@rrep.name}" },
        { key: :resource_desc },
        { value: @rrep.desc.class.name },
        :check_delete
      ]
    end
  end
end
