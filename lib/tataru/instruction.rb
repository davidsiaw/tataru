# frozen_string_literal: true

module Tataru
  # a thing to do
  class Instruction
    class << self
      attr_accessor :expected_params

      def expects(symbol)
        @expected_params ||= []
        @expected_params << symbol

        define_method symbol do
          return nil if @memory&.hash.nil?

          memory.hash[:temp][symbol]
        end
      end
    end

    attr_accessor :memory

    def execute(memory)
      @memory = memory
      self.class.expected_params&.each do |symbol|
        unless memory.hash[:temp].key? symbol
          raise "required param #{symbol} not found"
        end
      end

      run
    end

    def run; end
  end
end

require 'tataru/instructions/immediate_mode_instruction'
require 'tataru/instructions/resource_instruction'
require 'tataru/instructions/check_instruction'
require 'tataru/instructions/check_delete_instruction'
require 'tataru/instructions/mark_deletable_instruction'
require 'tataru/instructions/clear_instruction'
require 'tataru/instructions/goto_if_instruction'
require 'tataru/instructions/key_instruction'
require 'tataru/instructions/value_rom_instruction'
require 'tataru/instructions/value_update_instruction'
require 'tataru/instructions/compare_instruction'
require 'tataru/instructions/delete_instruction'
require 'tataru/instructions/update_instruction'
require 'tataru/instructions/create_instruction'
require 'tataru/instructions/end_instruction'
require 'tataru/instructions/check_create_instruction'
require 'tataru/instructions/read_instruction'
require 'tataru/instructions/check_update_instruction'
require 'tataru/instructions/rescmp_instruction'
require 'tataru/instructions/call_instruction'
require 'tataru/instructions/value_instruction'
require 'tataru/instructions/return_instruction'
require 'tataru/instructions/init_instruction'
