# frozen_string_literal: true

module Tataru
  # tataru
  class Quest
    attr_reader :dsl

    def initialize(pool, current_state = {})
      @pool = pool
      @current_state = current_state
      @dsl = TopDsl.new(pool)
    end

    def construct(&block)
      @dsl.instance_eval(&block)
    end

    def extant_resources
      @current_state.transform_values do |info|
        info[:desc]
      end
    end

    def remote_ids
      @current_state.transform_values do |info|
        info[:name]
      end
    end

    def extant_dependencies
      @current_state.transform_values do |info|
        info[:dependencies]
      end
    end

    def instr_hash
      c = Compiler.new(@dsl, extant_resources, extant_dependencies)
      result = c.instr_hash
      result[:init][:remote_ids] = remote_ids
      result
    end
  end
end
