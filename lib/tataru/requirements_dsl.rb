# frozen_string_literal: true

module Tataru
  # Requirements DSL
  class RequirementsDSL
    attr_reader :resource_list

    def initialize(resource_finder)
      @resource_finder = resource_finder
      @resource_list = {}
    end

    def respond_to_missing?
      true
    end

    def method_missing(type, name, &block)
      rclass = @resource_finder.resource_named(type)
      res = ResourceDSL.new(rclass.new)
      res.instance_exec(&block) if block
      resource_list[name] = {
        type: type,
        dependencies: [],
        state: res.fields
      }
    rescue NameError
      super
    end
  end
end
