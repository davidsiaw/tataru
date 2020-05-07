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
    @properties[name] = resolver.representation
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
    check_required_fields!
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

# compiler
class Compiler
  def initialize(dsl)
    @dsl = dsl
  end

  def instr_hash
    generate!
    {
      init: @init_hash,
      instructions: @instructions
    }
  end

  def generate!
    @instructions = []
    @labels = {}
    @init_hash = generate_init_hash

    @instructions << :init
    generate_instructions!
    @instructions << :end

    generate_subroutines!
  end

  def generate_instructions!
    order = Bunny::Tsort.tsort(@dsl.dep_graph)
    order.each do |level|
      checks = []
      level.each do |item|
        @instructions << { call: "create_#{item}" }
        checks << { call: "check_create_#{item}" }
      end
      @instructions += checks
    end
  end

  def generate_subroutines!
    @dsl.resources.each do |name, rr|
      idx = @instructions.count
      @labels["create_#{name}"] = idx
      @instructions += create_subroutine(rr)
      idx = @instructions.count
      @labels["check_create_#{name}"] = idx
      @instructions += check_create_subroutine(rr)
    end
  end

  def create_subroutine(representation)
    [
      :clear,
      { key: :resource_name },
      { value: representation.name },
      { key: :resource_desc },
      { value: representation.desc.class.name },
      { key: :properties },
      { value_rom: representation.name },
      :create,
      :return
    ]
  end

  def check_create_subroutine(representation)
    [
      :clear,
      { key: :resource_name },
      { value: representation.name },
      { key: :resource_desc },
      { value: representation.desc.class.name },
      :check_create,
      :return
    ]
  end

  def resolved_references(resource_name, references)
    references.map do |field, refname|
      [field, refname.to_s.sub(/^top/, resource_name)]
    end.to_h
  end

  def generate_init_hash
    rom = {}
    @dsl.resources.each do |k, v|
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
      remote_ids: {},
      labels: @labels
    }
  end
end

# tataru
class Tataru
  def initialize(pool)
    @pool = pool
    @dsl = TopDsl.new(pool)
  end

  def construct(&block)
    @dsl.instance_eval(&block)
  end

  def instr_hash
    c = Compiler.new(@dsl)
    c.instr_hash
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
    raise 'unknown instruction' unless Kernel.const_defined? instr_const

    Kernel.const_get(instr_const)
  end

  def init_instruction
    init = InitInstruction.new

    inithash = @thehash[:init]
    if inithash
      %i[remote_ids outputs errors deleted rom labels].each do |member|
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
  attr_accessor :remote_ids, :outputs, :errors, :rom, :labels, :deleted

  def initialize
    @remote_ids = {}
    @outputs = {}
    @errors = {}
    @rom = {}
    @labels = {}
    @deleted = []
  end

  def run
    memory.hash[:remote_ids] = @remote_ids
    memory.hash[:outputs] = @outputs
    memory.hash[:errors] = @errors
    memory.hash[:labels] = @labels
    memory.hash[:rom] = @rom.freeze
    memory.hash[:deleted] = @deleted
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
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])

    return unless desc.output_fields.count

    memory.hash[:outputs][resource_name] = resource.outputs
  end
end

# instruction to delete
class DeleteInstruction < ResourceInstruction
  def run
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])
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
  expects :property_names

  def run
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])
    memory.hash[:temp][resource_name] = resource.read(property_names)
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
    resource_class = desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][resource_name])

    return unless desc.output_fields.count

    memory.hash[:outputs][resource_name] = resource.outputs
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

# sets a hash entry and resolves from rom what was set
class ValueRomInstruction < ImmediateModeInstruction
  def run
    return memory.error = 'No key set' unless memory.hash[:temp].key? :_key

    key = memory.hash[:temp].delete :_key
    memory.hash[:temp][key] = resolve(rom_object)
  end

  def rom
    memory.hash[:rom]
  end

  def rom_object
    raise 'Not found' unless rom.key? @param

    rom[@param]
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
    memory.hash[:outputs][object[:resource]][object[:output]]
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
