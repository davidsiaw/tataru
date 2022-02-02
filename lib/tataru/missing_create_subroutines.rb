# frozen_string_literal: true

module Tataru
  # subroutines for missing create
  module MissingCreateSubroutines
    def missing_create_instructions
      [
        # mark as missing so the creation is checked
        { key: :superkey },
        { value: :update_action },
        { key: :key },
        { value: @rrep.name },
        { memwrite: :missing },

        # clear the remote id because it is not valid
        { key: :superkey },
        { value: :remote_ids },
        { key: :key },
        { value: @rrep.name },
        { memwrite: nil },

        # proceed to create
        *create_instructions
      ]
    end

    def missing_create_check_instructions
      [
        *check_create_instructions
      ]
    end
  end
end
