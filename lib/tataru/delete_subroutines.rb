# frozen_string_literal: true

module Tataru
  # delete subroutines
  module DeleteSubroutines
    def delete_instructions
      return [] if desc.delete_at_end?

      [
        *load_resource_instructions,
        :delete
      ]
    end

    def check_delete_instructions
      return [] if desc.delete_at_end?

      [
        *load_resource_instructions,
        :check_delete
      ]
    end

    def commit_delete_instructions
      return [] unless desc.delete_at_end?

      [
        *load_resource_instructions,
        :delete
      ]
    end

    def finish_delete_instructions
      return [] unless desc.delete_at_end?

      [
        *load_resource_instructions,
        :check_delete
      ]
    end
  end
end
