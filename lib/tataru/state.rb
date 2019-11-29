# frozen_string_literal: true

module Tataru
  # The state of the environment
  class State
    def initialize
      @current_ids = {}
      @replacer_ids = {}
    end

    def putstate(id, state, value, replacer: false)
      ids = id_list(replacer)
      ids[id] = {} unless ids.key? id
      ids[id][state] = value
    end

    def getstate(id, state, replacer: false)
      ids = id_list(replacer)
      return unless ids.key? id

      ids[id][state]
    end

    def id_list(replacer = false)
      return @replacer_ids if replacer

      @current_ids
    end

    def delete_list
      @replacer_ids.keys.select { |x| @current_ids.key? x }
    end

    def [](id)
      @current_ids[id].clone
    end
  end
end
