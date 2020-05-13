# frozen_string_literal: true

module Tataru
  # tataru
  class Quest
    def initialize(pool, current_state = {})
      @pool = pool
      @current_state = current_state
      @dsl = TopDsl.new(pool)
    end

    def construct(&block)
      @dsl.instance_eval(&block)
    end

    def extant_resources
      @current_state.map do |resname, info|
        [resname, info[:desc]]
      end.to_h
    end

    def remote_ids
      @current_state.map do |resname, info|
        [resname, info[:name]]
      end.to_h
    end

    def extant_dependencies
      @current_state.map do |resname, info|
        [resname, info[:dependencies]]
      end.to_h
    end

    def instr_hash
      c = Compiler.new(@dsl, extant_resources, extant_dependencies)
      result = c.instr_hash
      result[:init][:remote_ids] = remote_ids
      result
    end
  end
end
