# frozen_string_literal: true

module Tataru
  module Instructions
    # instruction to initialize the memory
    class InitInstruction < Instruction
      attr_accessor :remote_ids, :outputs, :rom, :labels, :deleted

      def initialize
        @remote_ids = {}
        @outputs = {}
        @rom = {}
        @labels = {}
        @deleted = []
      end

      def run
        memory.hash[:remote_ids] = @remote_ids
        memory.hash[:outputs] = @outputs
        memory.hash[:labels] = @labels
        memory.hash[:rom] = @rom.freeze
        memory.hash[:deleted] = @deleted
        memory.hash[:update_action] = {}
      end
    end
  end
end
