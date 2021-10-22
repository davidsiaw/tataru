# frozen_string_literal: true

module Tataru
  # representation of a set of instructions
  class InstructionHash
    def initialize(thehash)
      @thehash = thehash
    end

    def instruction_list
      @instruction_list ||= instructions
    end

    def to_h
      @thehash
    end

    def instructions
      return [] unless @thehash[:instructions]

      @thehash[:instructions].map do |action|
        case action
        when :init
          init_instruction
        when Hash
          # immediate mode instruction
          instruction_for(action.keys[0]).new(action.values[0])
        else
          instruction_for(action).new
        end
      end.to_a
    end

    def instruction_for(action)
      instr_const = "#{action}_instruction".camelize
      raise "Unknown instruction '#{action}'" unless Tataru::Instructions.const_defined? instr_const

      Tataru::Instructions.const_get(instr_const)
    end

    def init_instruction
      init = Tataru::Instructions::InitInstruction.new

      inithash = @thehash[:init]
      if inithash
        %i[remote_ids outputs deleted rom labels].each do |member|
          init.send(:"#{member}=", inithash[member]) if inithash.key? member
        end
      end
      init
    end
  end
end
