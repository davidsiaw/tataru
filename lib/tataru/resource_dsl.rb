# frozen_string_literal: true

module Tataru
  # Resource DSL
  class ResourceDSL
    attr_reader :fields

    def initialize(resource_inst)
      @resource_inst = resource_inst
      @fields = {}
    end

    def respond_to_missing?
      true
    end

    def method_missing(state_name, *args, &block)
      if @resource_inst.respond_to?("#{state_name}_change_action")
        @fields[state_name] = args[0]
      else
        super
      end
    end

    def errors
      (@resource_inst.states - @fields.keys).map do |x|
        { missing_state: x }
      end
    end
  end
end
