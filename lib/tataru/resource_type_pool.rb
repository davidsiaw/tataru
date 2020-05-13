# frozen_string_literal: true

module Tataru
  # class resource type pool
  class ResourceTypePool
    def initialize
      @pool = {}
    end

    def add_resource_desc(symbol, classconstant)
      @pool[symbol] = classconstant
    end

    def resource_desc_for(symbol)
      @pool[symbol]
    end

    def resource_desc_exist?(symbol)
      @pool.key? symbol
    end
  end
end
