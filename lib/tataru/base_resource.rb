# frozen_string_literal: true

module Tataru
  # base class of resource
  class BaseResource
    attr_reader :remote_id

    def initialize(remote_id)
      @remote_id = remote_id
    end

    def create(_name_value_hash)
      # create the resource
    end

    def read(_name_array)
      # read a range of resource fields
      {}
    end

    def update(name_value_hash)
      # update the resource fields
    end

    def delete
      # delete the resource
    end

    def outputs
      # resource outputs
      {}
    end

    def exist?
      # check that resource exists
      true
    end

    def create_complete?
      # check if creation is complete
      true
    end

    def update_complete?
      # check if update is complete
      true
    end

    def delete_complete?
      # check if delete is complete
      true
    end
  end
end
