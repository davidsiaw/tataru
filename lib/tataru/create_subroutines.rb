# frozen_string_literal: true

module Tataru
  # create subroutines
  module CreateSubroutines
    def create_instructions
      @rrep.check_required_fields!
      [
        *load_resource_instructions,
        { key: :properties },
        { value_rom: @rrep.name },
        :create
      ]
    end

    def check_create_instructions
      [
        *load_resource_instructions,
        :check_create
      ]
    end

    def commit_create_instructions
      []
    end

    def finish_create_instructions
      []
    end
  end
end
