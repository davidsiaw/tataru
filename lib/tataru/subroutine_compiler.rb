# frozen_string_literal: true

module Tataru
  # a subroutine for handling a resource
  class SubroutineCompiler
    include CreateSubroutines
    include UpdateSubroutines
    include DeleteSubroutines

    def initialize(resource_representation, create_missing, action)
      @rrep = resource_representation
      @action = action
      @create_missing = create_missing
    end

    def desc
      @rrep.desc
    end

    def label
      "#{@action}_#{@rrep.name}"
    end

    def base_action
      @action.to_s.split('_')[1].to_s
    end

    def body_instructions
      [
        :clear,
        *inner_instructions,
        :return
      ]
    end

    def load_resource_instructions
      [
        { key: :resource_name },
        { value: @rrep.name },
        { key: :resource_desc },
        { value: @rrep.desc.class.name }
      ]
    end

    def inner_instructions
      send :"#{@action}_instructions"
    end

    def call_instruction
      { call: label }
    end
  end
end
