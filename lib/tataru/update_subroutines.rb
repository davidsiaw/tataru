# frozen_string_literal: true

module Tataru
  # update subroutines
  module UpdateSubroutines
    def update_instructions
      [
        *load_resource_instructions,
        :read,
        *load_resource_instructions,
        :rescmp,
        { value_update: @rrep.name },
        { compare: :recreate },
        { goto_if: "recreate_#{@rrep.name}" },
        { value_update: @rrep.name },
        { compare: :modify },
        { goto_if: "modify_#{@rrep.name}" }
      ]
    end

    def check_update_instructions
      [
        { value_update: @rrep.name },
        { compare: :recreate },
        { goto_if: "recreate_check_#{@rrep.name}" },
        { value_update: @rrep.name },
        { compare: :modify },
        { goto_if: "modify_check_#{@rrep.name}" }
      ]
    end

    def commit_update_instructions
      [
        { value_update: @rrep.name },
        { compare: :recreate },
        { goto_if: "recreate_commit_#{@rrep.name}" }
      ]
    end

    def finish_update_instructions
      [
        { value_update: @rrep.name },
        { compare: :recreate },
        { goto_if: "recreate_finish_#{@rrep.name}" }
      ]
    end

    def modify_instructions
      [
        *load_resource_instructions,
        { key: :properties },
        { value_rom: @rrep.name },
        :update
      ]
    end

    def modify_check_instructions
      [
        *load_resource_instructions,
        :check_update
      ]
    end

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
