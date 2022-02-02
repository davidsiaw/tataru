# frozen_string_literal: true

require 'tataru/recreate_subroutines'
require 'tataru/missing_create_subroutines'

module Tataru
  # update subroutines
  module UpdateSubroutines
    include RecreateSubroutines
    include MissingCreateSubroutines

    def update_instructions
      [
        *create_missing_resource_instructions,
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

    def create_missing_resource_instructions
      [
        *load_resource_instructions,
        :check_exist,
        { compare: true },
        *missing_resource_action
      ]
    end

    def missing_resource_action
      return [{ assert: :resource_not_exist }] unless @create_missing

      [
        :invert,
        { goto_if: "missing_create_#{@rrep.name}" }
      ]
    end

    def check_update_instructions
      [
        { value_update: @rrep.name },
        { compare: :missing },
        { goto_if: "missing_create_check_#{@rrep.name}" },
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
        *load_resource_instructions,
        :read,
        *load_resource_instructions,
        :filter,
        :update
      ]
    end

    def modify_check_instructions
      [
        *load_resource_instructions,
        :check_update
      ]
    end
  end
end
