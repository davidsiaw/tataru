# frozen_string_literal: true

require 'bunny/tsort'

module Tataru
  # compiler
  class Compiler
    def initialize(dsl, create_missing, extant_resources = {}, extant_dependencies = {})
      @dsl = dsl
      @extant = extant_resources
      @extant_dependencies = extant_dependencies
      @create_missing = create_missing
    end

    def instr_hash
      {
        init: {
          **InitHashCompiler.new(@dsl).result,
          labels: labels
        },
        instructions: top_instructions + subroutine_instructions
      }
    end

    def labels
      @labels ||= generate_labels
    end

    def subroutines
      @subroutines ||= generate_subroutines
    end

    def top_instructions
      @top_instructions ||= [
        :init,
        *generate_top_instructions,
        :end
      ]
    end

    def subroutine_instructions
      @subroutine_instructions ||=
        subroutines.values.flat_map(&:body_instructions)
    end

    def generate_labels
      count = 0
      subroutines.values.map do |sub|
        arr = [sub.label, top_instructions.count + count]
        count += sub.body_instructions.count
        arr
      end.to_h
    end

    def deletables
      @extant.reject { |k, _| @dsl.resources.key? k }
    end

    def updatables
      @dsl.resources
    end

    def generate_subroutines
      result = {}
      result.merge!(deletion_resources)
      result.merge!(update_resources)
      result
    end

    def deletion_resources
      result = {}
      # set up resources for deletion
      deletables.each do |k, v|
        desc = Tataru.const_get(v).new
        rrep = Representations::ResourceRepresentation.new(k, desc, {})
        sp = SubPlanner.new(rrep, :delete, @create_missing)
        result.merge!(sp.subroutines)
      end
      result
    end

    def update_resources
      result = {}
      # set up resources for updates or creates
      updatables.each do |k, rrep|
        action = @extant.key?(k) ? :update : :create
        sp = SubPlanner.new(rrep, action, @create_missing)
        result.merge!(sp.subroutines)
      end
      result
    end

    def generate_step_order(order, steps)
      instructions = []
      order.each do |level|
        steps.each do |step|
          instructions += level.map do |item|
            subroutines["#{item}_#{step}"].call_instruction
          end
        end
      end
      instructions
    end

    def generate_top_instructions
      order = Bunny::Tsort.tsort(@extant_dependencies.merge(@dsl.dep_graph))

      generate_step_order(order, %i[start check]) +
        generate_step_order(order.reverse, %i[commit finish])
    end
  end
end
