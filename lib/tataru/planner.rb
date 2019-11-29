# frozen_string_literal: true

module Tataru
  # A plan
  class Planner
    def initialize(current_state, requirement)
      @current_state = current_state
      @requirement = requirement
      @actions = {}
    end

    def order
      Bunny::Tsort.tsort(@requirement.dep_tree)
    end

    def delete_instruction_for(id)
      Instruction.new(:delete, id, @current_state[id])
    end

    def generate_delete_instruction_for(id)
      return if @current_state[id].nil?
      return unless action(id) == :replace

      delete_instruction_for(id)
    end

    def generate_instruction_for(id)
      if @current_state[id].nil?
        Instruction.new(:create, id, end_state[id])
      elsif action(id) == :replace
        Instruction.new(:create, id, end_state[id])
      elsif action(id) == :update
        Instruction.new(:update, id, end_state[id])
      end
    end

    def generate_removal_instructions
      remove_actions = []
      @current_state.id_list.keys.each do |id|
        next if @requirement.exist? id

        remove_actions << delete_instruction_for(id)
      end
      remove_actions
    end

    def generate_delete_instructions
      delete_actions = []
      order.each do |step|
        step.each do |id|
          delete_action = generate_delete_instruction_for(id)
          delete_actions << delete_action unless delete_action.nil?
        end
      end
      delete_actions + generate_removal_instructions
    end

    def generate_instructions
      instr = []
      order.each do |step|
        step.each do |id|
          instruction = generate_instruction_for(id)
          instr << instruction unless instruction.nil?
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
