# frozen_string_literal: true

module Tataru
  module Rage
    # not valid
    class InvalidRequirement < StandardError; end
  end


  # A plan
  class Planner
    def initialize(current_state, requirement)
      @current_state = current_state
      @requirement = requirement
      @actions = {}

      raise Rage::InvalidRequirement unless requirement.valid?
    end

    def order
      Bunny::Tsort.tsort(@requirement.dep_tree)
    end

    def delete_instruction_for(id, pref)
      Instruction.new(:"#{pref}_delete", id, @current_state[id], @requirement)
    end

    def generate_delete_instruction_for(id, pref)
      return if @current_state[id].nil?
      return unless action(id) == :replace

      delete_instruction_for(id, pref)
    end

    def generate_instruction_for(id, pref)
      if @current_state[id].nil?
        Instruction.new(:"#{pref}_create", id, end_state[id], @requirement)
      elsif action(id) == :replace
        Instruction.new(:"#{pref}_create", id, end_state[id], @requirement)
      elsif action(id) == :update
        Instruction.new(:"#{pref}_update", id, end_state[id], @requirement)
      end
    end

    def generate_removal_instructions
      remove_actions = []
      @current_state.id_list.keys.each do |id|
        next if @requirement.exist? id

        remove_actions << delete_instruction_for(id, :begin)
      end
      remove_actions
    end

    def generate_delete_instructions
      delete_actions = []
      order.reverse.each do |step|
        %i[begin wait].each do |substep|
          step.each do |id|
            delete_action = generate_delete_instruction_for(id, substep)
            delete_actions << delete_action unless delete_action.nil?
          end
        end
      end
      delete_actions + generate_removal_instructions
    end

    def generate_instructions
      instr = []
      order.each do |step|
        %i[begin wait].each do |substep|
          step.each do |id|
            instruction = generate_instruction_for(id, substep)
            instr << instruction unless instruction.nil?
          end
        end
      end
      instr + generate_delete_instructions
    end

    def instructions
      @instructions ||= generate_instructions
    end

    def action(id)
      @actions[id] ||= @requirement.action(id, @current_state[id])
    end

    def end_state
      @requirement.end_state
    end
  end
end
