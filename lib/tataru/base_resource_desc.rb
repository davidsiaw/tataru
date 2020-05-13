# frozen_string_literal: true

module Tataru
  # description of a resource
  class BaseResourceDesc
    def resource_class
      # returns the class of the resource
      BaseResource
    end

    def mutable_fields
      [] # fields that can be passed in to create and update
    end

    def immutable_fields
      [] # fields that cannot be passed in to update but can be passed to create
    end

    def output_fields
      [] # fields that cannot be passed in to create or update
    end

    def required_fields
      [] # mutable or immutable fields that cannot be omitted
    end

    def needs_remote_id?
      false # true if resource requires a remote id
    end

    def delete_at_end?
      false # if true moves deletes to end of program
    end
  end
end
