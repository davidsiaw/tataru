# frozen_string_literal: true

require 'tataru/rom_reader'
require 'tataru/base_resource'
require 'tataru/base_resource_desc'
require 'tataru/representation'
require 'tataru/resource_dsl'
require 'tataru/resolver'
require 'tataru/top_dsl'
require 'tataru/flattener'
require 'tataru/create_subroutines'
require 'tataru/delete_subroutines'
require 'tataru/update_subroutines'
require 'tataru/subroutine_compiler'
require 'tataru/init_hash_compiler'
require 'tataru/sub_planner'
require 'tataru/compiler'
require 'tataru/quest'
require 'tataru/resource_type_pool'
require 'tataru/instruction_hash'
require 'tataru/instruction'
require 'tataru/memory'
require 'tataru/runner'

module Tataru
  # Entry class
  class Taru
    def initialize(rtp, current_state = {}, &block)
      @rtp = rtp
      @current_state = current_state
      @quest = Tataru::Quest.new(rtp, current_state)
      @quest.construct(&block)
      @ih = Tataru::InstructionHash.new(@quest.instr_hash)
      @runner = Tataru::Runner.new(@ih.instruction_list)
    end

    def step
      @runner.run_next
      !@runner.ended?
    end

    def oplog
      @runner.oplog
    end

    def error
      @runner.memory.error
    end

    def state
      @runner.memory.hash[:remote_ids].map do |k, v|
        extract_state(k, v)
      end.to_h
    end

    def extract_state(key, value)
      if key.start_with? '_deletable_'
        original_key = key.sub(/^_deletable_/, '')
        [key, {
          name: value,
          desc: @current_state[original_key][:desc],
          dependencies: @current_state[original_key][:dependencies]
        }]
      else
        [key, {
          name: value,
          desc: @quest.dsl.resources[key].desc.class.name,
          dependencies: @quest.dsl.dep_graph[key]
        }]
      end
    end
  end
end
