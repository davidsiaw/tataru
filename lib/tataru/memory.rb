# frozen_string_literal: true

module Tataru
  # memory that can be manipulated by instructions
  class Memory
    attr_accessor :program_counter, :hash, :call_stack, :error, :end

    def initialize
      @program_counter = 0
      @hash = { temp: {} }
      @error = nil
      @call_stack = []
      @end = false
    end
  end
end
