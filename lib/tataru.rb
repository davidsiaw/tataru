# frozen_string_literal: true

require 'active_support/inflector'
require 'bunny/tsort'

# base class of resource
class BaseResource
  attr_reader :remote_id

  def initialize(remote_id)
    @remote_id = remote_id
  end

  def create(_name_value_hash)
    # create the resource
  end

  def read(_name_array)
    # read a range of resource fields
    {}
  end

  def update(name_value_hash)
    # update the resource fields
  end

  def delete
    # delete the resource
  end

  def outputs
    # resource outputs
    {}
  end

  def create_complete?
    # check if creation is complete
    true
  end

  def update_complete?
    # check if update is complete
    true
  end

  def delete_complete?
    # check if delete is complete
    true
  end
end

# description of a resource
class BaseResourceDesc
  def resource_class
    # returns the class of the resource
    BaseResource
  end

  def mutable_fields
    [] # fields that can be passed in to create and update
  end

  def immutable_fields
    [] # fields that cannot be passed in to update but can be passed to create
  end

  def output_fields
    [] # fields that cannot be passed in to create or update
  end

  def required_fields
    [] # mutable or immutable fields that cannot be omitted
  end

  def needs_remote_id?
    false # true if resource requires a remote id
  end

  def delete_at_end?
    false # if true moves deletes to end of program
  end
end

# resolver for data
class Resolver
  def initialize(expression)
    @expression = expression
  end

  def representation
    @representation ||= case @expression
                        when String
                          LiteralRepresentation.new(@expression)
                        when Numeric
                          LiteralRepresentation.new(@expression)
                        when Array
                          ArrayRepresentation.new(@expression)
                        when Hash
                          HashRepresentation.new(@expression)
                        when ResourceRepresentation
                          @expression
                        when OutputRepresentation
                          @expression
                        else
                          raise "invalid value: #{@expression.inspect}"
                        end
  end

  def dependencies
    representation.dependencies
  end
end

# human representation of resources
class ResourceDsl
  def initialize(name, desc)
    @properties = {}
    @desc = desc
    @fields = Set.new(@desc.mutable_fields + @desc.immutable_fields)
    @name = name
    @dependencies = Set.new
  end

  def respond_to_missing?(name, *_args)
    true if @fields.include? name
  end

  def method_missing(name, *args, &block)
    return super unless @fields.include? name

    resolver = Resolver.new(args[0])
    @dependencies += resolver.dependencies
    @properties[name] = if resolver.representation.is_a? ResourceRepresentation
                          resolver.representation.remote_id
                        else
                          resolver.representation
                        end
  end

  def representation
    ResourceRepresentation.new(@name, @desc, @properties)
  end
end

# base representation
class Representation
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def dependencies
    []
  end
end

# representing simple values
class LiteralRepresentation < Representation
end

# representing arrays
class ArrayRepresentation < Representation
  def initialize(value)
    @value = value.map do |thing|
      Resolver.new(thing).representation
    end.to_a
  end

  def dependencies
    @dependencies ||= @value.flat_map(&:dependencies)
  end
end

# representing hashes
class HashRepresentation < Representation
  def initialize(value)
    @value = value.map do |key, thing|
      [key, Resolver.new(thing).representation]
    end.to_h
  end

  def dependencies
    @dependencies ||= @value.flat_map do |_key, rep|
      rep.dependencies
    end
  end
end

# internal representation of resources
class ResourceRepresentation < Representation
  attr_reader :name, :properties, :desc

  def initialize(name, desc, properties)
    @name = name
    @properties = properties
    @desc = desc
    check_late_deletability!
  end

  def check_late_deletability!
    return unless @desc.delete_at_end? && !@desc.needs_remote_id?

    raise 'must need remote id if deletes at end'
  end

  def check_required_fields!
    @desc.required_fields.each do |field|
      next if @properties.key? field

      raise "Required field '#{field}' not provided in '#{@name}'"
    end
  end

  def respond_to_missing?(name, *_args)
    true if @desc.output_fields.include? name
  end

  def remote_id
    OutputRepresentation.new(@name, :remote_id)
  end

  def method_missing(name, *args, &block)
    return super unless @desc.output_fields.include? name

    OutputRepresentation.new(@name, name)
  end

  def dependencies
    [@name]
  end
end

# internal representation of output
class OutputRepresentation < Representation
  attr_reader :resource_name, :output_field_name

  def initialize(resource_name, output_field_name)
    @resource_name = resource_name
    @output_field_name = output_field_name
  end

  def dependencies
    [@resource_name]
  end
end

# human representation of resources
class TopDsl
  attr_reader :resources

  def initialize(pool)
    @resources = {}
    @pool = pool
  end

  def resource(symbol, name, &block)
    unless @pool.resource_desc_exist?(symbol)
      raise "no such resource: #{symbol}"
    end
    raise "already defined: #{name}" if @resources.key? name

    resource = ResourceDsl.new(name, @pool.resource_desc_for(symbol).new)
    resource.instance_eval(&block) if block

    @resources[name] = resource.representation
  end

  def dep_graph
    @resources.map do |name, resource_representation|
      deps = Set.new
      resource_representation.properties.each do |_key, value|
        deps += value.dependencies
      end
      [name, deps.to_a]
    end.to_h
  end
end

# flattens properties to make them digestable
class Flattener
  def initialize(value)
    @value = value
    @result = {}
  end

  def flattened
    flatten(@value, :top)
    @result
  end

  def flatten(value, name)
    type = value.class.name.sub(/Representation$/, '').downcase
    method_name = :"flatten_#{type}"
    raise "cannot flatten #{value.inspect}" unless respond_to?(method_name)

    send(method_name, value, name)
  end

  def flatten_literal(value, name)
    @result[name] = {
      type: :literal,
      value: value.value
    }
  end

  def flatten_array(value, name)
    refs = {}
    value.value.each_with_index do |val, i|
      key = :"#{name}_#{i}"
      flatten(val, key)
      refs[i] = key
    end
    @result[name] = {
      type: :array,
      references: refs
    }
  end

  def flatten_hash(value, name)
    refs = {}
    value.value.each do |k, v|
      key = :"#{name}_#{k}"
      flatten(v, key)
      refs[k] = key
    end
    @result[name] = {
      type: :hash,
      references: refs
    }
  end

  def flatten_resource(value, name)
    refs = {}
    value.properties.each do |k, v|
      key = :"#{name}_#{k}"
      flatten(v, key)
      refs[k] = key
    end
    @result[name] = {
      type: :hash,
      references: refs
    }
  end

  def flatten_output(value, name)
    @result[name] = {
      type: :output,
      resource: value.resource_name,
      output: value.output_field_name
    }
  end
end

# a subroutine for handling a resource
class SubroutineCompiler
  def initialize(resource_representation, action)
    @rrep = resource_representation
    @action = action
  end

  def desc
    @rrep.desc
  end

  def label
    "#{@action}_#{@rrep.name}"
  end

  def base_action
    @action.to_s.split('_')[1].to_s
  end

  def body_instructions
    [
      :clear,
      *inner_instructions,
      :return
    ]
  end

  def load_resource_instructions
    [
      { key: :resource_name },
      { value: @rrep.name },
      { key: :resource_desc },
      { value: @rrep.desc.class.name }
    ]
  end

  def inner_instructions
    send :"#{@action}_instructions"
  end

  def create_instructions
    @rrep.check_required_fields!
    [
      *load_resource_instructions,
      { key: :properties },
      { value_rom: @rrep.name },
      :create
    ]
  end

  def check_create_instructions
    [
      *load_resource_instructions,
      :check_create
    ]
  end

  def commit_create_instructions
    []
  end

  def finish_create_instructions
    []
  end

  def update_instructions
    [
      *load_resource_instructions,
      :read,
      *load_resource_instructions,
      :rescmp,
      { value_update: @rrep.name },
      { compare: :recreate },
      { goto_if: "recreate_#{@rrep.name}" },
      { value_update: @rrep.name },
      { compare: :modify },
      { goto_if: "modify_#{@rrep.name}" }
    ]
  end

  def check_update_instructions
    [
      { value_update: @rrep.name },
      { compare: :recreate },
      { goto_if: "recreate_check_#{@rrep.name}" },
      { value_update: @rrep.name },
      { compare: :modify },
      { goto_if: "modify_check_#{@rrep.name}" }
    ]
  end

  def commit_update_instructions
    [
      { value_update: @rrep.name },
      { compare: :recreate },
      { goto_if: "recreate_commit_#{@rrep.name}" }
    ]
  end

  def finish_update_instructions
    [
      { value_update: @rrep.name },
      { compare: :recreate },
      { goto_if: "recreate_finish_#{@rrep.name}" }
    ]
  end

  def modify_instructions
    [
      *load_resource_instructions,
      { key: :properties },
      { value_rom: @rrep.name },
      :update
    ]
  end

  def modify_check_instructions
    [
      *load_resource_instructions,
      :check_update
    ]
  end

  def recreate_instructions
    deletion_routine = [
      *load_resource_instructions,
      :mark_deletable
    ]
    unless desc.delete_at_end?
      deletion_routine = [
        *delete_instructions,
        *check_delete_instructions
      ]
    end
    [
      *deletion_routine,
      *create_instructions
    ]
  end

  def recreate_check_instructions
    [
      *check_create_instructions
    ]
  end

  def recreate_commit_instructions
    return [] unless desc.delete_at_end?

    [
      { key: :resource_name },
      { value: "_deletable_#{@rrep.name}" },
      { key: :resource_desc },
      { value: @rrep.desc.class.name },
      :delete
    ]
  end

  def recreate_finish_instructions
    return [] unless desc.delete_at_end?

    [
      { key: :resource_name },
      { value: "_deletable_#{@rrep.name}" },
      { key: :resource_desc },
      { value: @rrep.desc.class.name },
      :check_delete
    ]
  end

  def delete_instructions
    return [] if desc.delete_at_end?

    [
      *load_resource_instructions,
      :delete
    ]
  end

  def check_delete_instructions
    return [] if desc.delete_at_end?

    [
      *load_resource_instructions,
      :check_delete
    ]
  end

  def commit_delete_instructions
    return [] unless desc.delete_at_end?

    [
      *load_resource_instructions,
      :delete
    ]
  end

  def finish_delete_instructions
    return [] unless desc.delete_at_end?

    [
      *load_resource_instructions,
      :check_delete
    ]
  end

  def call_instruction
    { call: label }
  end
end

# compiles the inithash
class InitHashCompiler
  def initialize(dsl)
    @dsl = dsl
  end

  def resolved_references(resource_name, references)
    references.map do |field, refname|
      [field, refname.to_s.sub(/^top/, resource_name)]
    end.to_h
  end

  def generate_init_hash
    rom = {}
    @dsl.resources.each do |k, v|
      # Expand all the values used to a big flat hash that
      # is only one level deep for ease of use, then mark
      # them for the vm to use
      flattener = Flattener.new(v)
      flattener.flattened.each do |key, value|
        fixed = value.dup
        if fixed[:references]
          fixed[:references] = resolved_references(k, fixed[:references])
        end
        rom[key.to_s.sub(/^top/, k)] = fixed
      end
    end
    {
      rom: rom,
      remote_ids: {}
    }
  end

  def result
    @result ||= generate_init_hash
  end
end

# returns subroutines required based on the resource
class SubPlanner
  def initialize(rrep, action)
    @rrep = rrep
    @action = action
  end

  def name
    @rrep.name
  end

  def compile(*args)
    SubroutineCompiler.new(@rrep, *args)
  end

  def extra_subroutines
    return {} unless @action == :update

    {
      "#{name}_modify" => compile(:modify),
      "#{name}_modify_check" => compile(:modify_check),
      "#{name}_recreate" => compile(:recreate),
      "#{name}_recreate_check" => compile(:recreate_check),
      "#{name}_recreate_commit" => compile(:recreate_commit),
      "#{name}_recreate_finish" => compile(:recreate_finish)
    }
  end

  def subroutines
    {
      "#{name}_start" => compile(:"#{@action}"),
      "#{name}_check" => compile(:"check_#{@action}"),
      "#{name}_commit" => compile(:"commit_#{@action}"),
      "#{name}_finish" => compile(:"finish_#{@action}")
    }.merge(extra_subroutines)
  end
end

# compiler
class Compiler
  def initialize(dsl, extant_resources = {}, extant_dependencies = {})
    @dsl = dsl
    @extant = extant_resources
    @extant_dependencies = extant_dependencies
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
    # set up resources for deletion
    deletables.each do |k, v|
      desc = Kernel.const_get(v).new
      rrep = ResourceRepresentation.new(k, desc, {})
      sp = SubPlanner.new(rrep, :delete)
      result.merge!(sp.subroutines)
    end

    # set up resources for updates or creates
    updatables.each do |k, rrep|
      action = @extant.key?(k) ? :update : :create
      sp = SubPlanner.new(rrep, action)
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

# tataru
class Tataru
  def initialize(pool, current_state = {})
    @pool = pool
    @current_state = current_state
    @dsl = TopDsl.new(pool)
  end

  def construct(&block)
    @dsl.instance_eval(&block)
  end

  def extant_resources
    @current_state.map do |resname, info|
      [resname, info[:desc]]
    end.to_h
  end

  def remote_ids
    @current_state.map do |resname, info|
      [resname, info[:name]]
    end.to_h
  end

  def extant_dependencies
    @current_state.map do |resname, info|
      [resname, info[:dependencies]]
    end.to_h
  end

  def instr_hash
    c = Compiler.new(@dsl, extant_resources, extant_dependencies)
    result = c.instr_hash
    result[:init][:remote_ids] = remote_ids
    result
  end
end

# class resource type pool
class ResourceTypePool
  def initialize
    @pool = {}
  end

  def add_resource_desc(symbol, classconstant)
    @pool[symbol] = classconstant
  end

  def resource_desc_for(symbol)
    @pool[symbol]
  end

  def resource_desc_exist?(symbol)
    @pool.key? symbol
  end
end

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
      if action == :init
        init_instruction
      elsif action.is_a? Hash
        # immediate mode instruction
        instruction_for(action.keys[0]).new(action.values[0])
      else
        instruction_for(action).new
      end
    end.to_a
  end

  def instruction_for(action)
    instr_const = "#{action}_instruction".camelize
    unless Kernel.const_defined? instr_const
      raise "Unknown instruction '#{action}'"
    end

    Kernel.const_get(instr_const)
  end

  def init_instruction
    init = InitInstruction.new

    inithash = @thehash[:init]
    if inithash
      %i[remote_ids outputs deleted rom labels].each do |member|
        init.send(:"#{member}=", inithash[member]) if inithash.key? member
      end
    end
    init
  end
end

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

# instructions that deal with resources
class ResourceInstruction < Instruction
  expects :resource_name
  expects :resource_desc

  def desc
    Kernel.const_get(resource_desc).new
  end
end

# instruction to create
class CreateInstruction < ResourceInstruction
  expects :properties

  def run
    resource_class = desc.resource_class
    resource = resource_class.new(nil)
    resource.create(properties)

    return unless desc.needs_remote_id?

    memory.hash[:remote_ids][resource_name] = resource.remote_id
  end
end

# General checking class
class CheckInstruction < ResourceInstruction
  def initialize(check_type)
    @check_type = check_type
  end

  def run
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])

    if resource.send(:"#{@check_type}_complete?")
      after_complete
    else
      # repeat this instruction until its done
      memory.program_counter -= 1
    end
  end

  def after_complete(_memory); end
end

# instruction to check create
class CheckCreateInstruction < CheckInstruction
  def initialize
    super :create
  end

  def after_complete
    memory.hash[:outputs][resource_name] = outputs
  end

  def outputs
    return {} unless desc.output_fields.count

    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])
    o = resource.outputs
    raise "Output for '#{resource_name}' is not a hash" unless o.is_a? Hash

    resource.outputs
  end
end

# puts remote id up for deletion
class MarkDeletableInstruction < ResourceInstruction
  def run
    remote_id = memory.hash[:remote_ids].delete(resource_name)
    memory.hash[:remote_ids]["_deletable_#{resource_name}"] = remote_id
  end
end

# instruction to delete
class DeleteInstruction < ResourceInstruction
  def run
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])
    resource.delete
  end
end

# check that delete is completed
class CheckDeleteInstruction < CheckInstruction
  def initialize
    super :delete
  end

  def after_complete
    memory.hash[:deleted] << resource_name

    return unless desc.needs_remote_id?

    memory.hash[:remote_ids].delete(resource_name)
  end
end

# read properties of resource
class ReadInstruction < ResourceInstruction
  def run
    results = resource.read(fields)
    memory.hash[:temp][resource_name] = {}
    fields.each do |k|
      memory.hash[:temp][resource_name][k] = results[k]
    end
  end

  def resource_class
    desc.resource_class
  end

  def resource
    resource_class.new(memory.hash[:remote_ids][resource_name])
  end

  def fields
    @fields ||= desc.immutable_fields + desc.mutable_fields
  end
end

# update a resource
class UpdateInstruction < ResourceInstruction
  expects :properties

  def run
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])
    resource.update(properties)
  end
end

# check that update is completed
class CheckUpdateInstruction < CheckInstruction
  def initialize
    super :update
  end

  def after_complete
    memory.hash[:outputs][resource_name] = outputs
  end

  def outputs
    return {} unless desc.output_fields.count

    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])
    o = resource.outputs
    raise "Output for '#{resource_name}' is not a hash" unless o.is_a? Hash

    resource.outputs
  end
end

# instruction that takes a parameter
class ImmediateModeInstruction < Instruction
  def initialize(param)
    @param = param
  end
end

# clears temp memory
class ClearInstruction < Instruction
  def run
    memory.hash[:temp] = {}
  end
end

# sets a key
class KeyInstruction < ImmediateModeInstruction
  def run
    memory.hash[:temp][:_key] = @param
  end
end

# sets a hash entry based on whatever key was set
class ValueInstruction < ImmediateModeInstruction
  def run
    return memory.error = 'No key set' unless memory.hash[:temp].key? :_key

    key = memory.hash[:temp].delete :_key
    memory.hash[:temp][key] = @param
  end
end

# Reads Rom values
module RomReader
  def rom
    memory.hash[:rom]
  end

  def resolve(object)
    case object[:type]
    when :literal
      object[:value]
    when :hash
      resolve_hash(object)
    when :array
      resolve_array(object)
    when :output
      resolve_output(object)
    end
  end

  def resolve_array(object)
    result = []
    object[:references].each do |k, v|
      result[k] = resolve(rom[v])
    end
    result
  end

  def resolve_hash(object)
    result = {}
    object[:references].each do |k, v|
      result[k] = resolve(rom[v])
    end
    result
  end

  def resolve_output(object)
    if object[:output] == :remote_id
      memory.hash[:remote_ids][object[:resource]]
    else
      memory.hash[:outputs][object[:resource]][object[:output]]
    end
  end
end

# sets temp result
class ValueUpdateInstruction < ImmediateModeInstruction
  def run
    unless memory.hash[:update_action].key? @param
      raise "No value set for '#{@param}'"
    end

    memory.hash[:temp] = {
      result: memory.hash[:update_action][@param]
    }
  end
end

# goto if temp result is non zero
class GotoIfInstruction < ImmediateModeInstruction
  def run
    return if memory.hash[:temp][:result].zero?

    memory.program_counter = if @param.is_a? Integer
                               @param - 1
                             else
                               label_branch!
                             end
  end

  def label_branch!
    unless memory.hash[:labels]&.key?(@param)
      raise "Label '#{@param}' not found"
    end

    memory.hash[:labels][@param] - 1
  end
end

# compares whats in temp result to param
class CompareInstruction < ImmediateModeInstruction
  def run
    memory.hash[:temp][:result] = if memory.hash[:temp][:result] == @param
                                    1
                                  else
                                    0
                                  end
  end
end

# compares resource in temp and resource in top
class RescmpInstruction < ResourceInstruction
  include RomReader

  def run
    raise 'Not found' unless rom.key? resource_name

    update!
  end

  def update!
    current = memory.hash[:temp][resource_name]
    desired = resolve(rom[resource_name])

    memory.hash[:update_action][resource_name] = compare(current, desired)
  end

  def compare(current, desired)
    result = :no_change
    desc.mutable_fields.each do |field|
      result = :modify if current[field] != desired[field]
    end
    desc.immutable_fields.each do |field|
      result = :recreate if current[field] != desired[field]
    end
    result
  end
end

# sets a hash entry and resolves from rom what was set
class ValueRomInstruction < ImmediateModeInstruction
  include RomReader

  def run
    return memory.error = 'No key set' unless memory.hash[:temp].key? :_key

    key = memory.hash[:temp].delete :_key
    memory.hash[:temp][key] = resolve(rom_object)
  end

  def rom_object
    raise 'Not found' unless rom.key? @param

    rom[@param]
  end
end

# pushes the callstack and branches
class CallInstruction < ImmediateModeInstruction
  def run
    labels = memory.hash[:labels]
    unless labels.key? @param
      memory.error = 'Label not found'
      return
    end

    memory.call_stack.push(memory.program_counter)
    memory.program_counter = labels[@param] - 1
  end
end

# pops the callstack and goes back
class ReturnInstruction < Instruction
  def run
    return memory.error = 'At bottom of stack' if memory.call_stack.count.zero?

    memory.program_counter = memory.call_stack.pop
  end
end

# ends the program
class EndInstruction < Instruction
  def run
    memory.end = true
  end
end

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

# thing that runs a quest
class Runner
  attr_reader :memory

  def initialize(instruction_list)
    @memory = Memory.new
    @instruction_list = instruction_list
  end

  def ended?
    @memory.program_counter >= @instruction_list.length ||
      !@memory.error.nil? ||
      @memory.end
  end

  def run_next
    return if ended?

    @instruction_list[@memory.program_counter].execute(@memory)
    @memory.program_counter += 1
  rescue RuntimeError => e
    @memory.error = e
  rescue StandardError => e
    @memory.error = e
  end
end
