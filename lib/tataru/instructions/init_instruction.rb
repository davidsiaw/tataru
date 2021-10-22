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
        super()
      end

      def run
        memory.hash = memory.hash.merge(
          remote_ids: @remote_ids,
          outputs: @outputs,
          labels: @labels,
          rom: @rom.freeze,
          deleted: @deleted,
          update_action: {}
        )
      end
    end
  end
end
