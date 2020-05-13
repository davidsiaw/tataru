# frozen_string_literal: true

module Tataru
  # thing that runs a quest
  class Runner
    attr_reader :memory, :oplog

    def initialize(instruction_list)
      @memory = Memory.new
      @instruction_list = instruction_list
      @oplog = []
    end

    def ended?
      @memory.program_counter >= @instruction_list.length ||
        !@memory.error.nil? ||
        @memory.end
    end

    def log_operation(instr)
      return unless instr.is_a? Instructions::ResourceInstruction

      oplog << {
        operation: instr.class.name.underscore
                        .sub(/_instruction$/, '').upcase.to_s,
        resource: (memory.hash[:temp][:resource_name]).to_s
      }
    end

    def run_next
      return if ended?

      instr = @instruction_list[@memory.program_counter]

      log_operation(instr)

      instr.execute(@memory)
      @memory.program_counter += 1
    rescue RuntimeError => e
      @memory.error = e
    rescue StandardError => e
      @memory.error = e
    end
  end
end
