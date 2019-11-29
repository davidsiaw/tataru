# frozen_string_literal: true

module Tataru
  # finds resource classes
  class DefaultResourceFinder
    def resource_named(name)
      Kernel.const_get("Tataru::Resources::#{name.to_s.camelize}Resource")
    end
  end
end
