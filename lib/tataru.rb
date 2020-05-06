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
                          raise 'invalid value.'
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

  def respond_to_missing?(name)
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
  def dependencies
    @dependencies ||= @value.flat_map do |value|
      Resolver.new(value).dependencies
    end
  end
end

# representing hashes
class HashRepresentation < Representation
  def dependencies
    @dependencies ||= @value.flat_map do |_key, value|
      Resolver.new(value).dependencies
    end
  end
end

# internal representation of resources
class ResourceRepresentation < Representation
  attr_reader :properties

  def initialize(name, desc, properties)
    @name = name
    @properties = properties
    @desc = desc
  end

  def respond_to_missing?(name)
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

# tataru
class Tataru
  def initialize(pool)
    @pool = pool
    @dsl = TopDsl.new(pool)
  end

  def construct(&block)
    @dsl.instance_eval(&block)
  end

  def instructions
    order = Bunny::Tsort.tsort(@dsl.dep_graph)
    order.each do |level|
      level.each do |item|
        
      end
    end
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
  def initialize(resource_type_pool, thehash)
    @thehash = thehash
    @resource_type_pool = resource_type_pool
  end

  def instruction_list
    result = [
      init_instruction,
      *instructions
    ]

    result
  end

  def to_h
    @thehash
  end

  def instructions
    return [] unless @thehash[:instructions]

    @thehash[:instructions].map do |infohash|
      next resource_instruction(infohash) if infohash[:type] == :resource

      raise 'unknown instruction'
    end.to_a
  end

  def resource_desc_for(resourcetype)
    @resource_type_pool.resource_desc_for(resourcetype)
  end

  def instruction_for(action)
    Kernel.const_get("#{action}_instruction".camelize)
  end

  def resource_instruction(infohash)
    resourcetype = infohash[:resourcetype]
    cls = instruction_for(infohash[:action])
    desc = resource_desc_for(resourcetype)
    args = [:new, infohash[:name], desc]
    args << infohash[:args] if infohash.key? :args
    cls.send(*args)
  end

  def init_instruction
    init = InitInstruction.new

    inithash = @thehash[:init]
    if inithash
      %i[remote_ids outputs errors deleted].each do |member|
        init.send(:"#{member}=", inithash[member]) if inithash.key? member
      end
    end
    init
  end
end

# a thing to do
class Instruction
  def run(_memory); end
end

# instruction to initialize the memory
class InitInstruction < Instruction
  attr_accessor :remote_ids, :outputs, :errors, :deleted

  def initialize
    @remote_ids = {}
    @outputs = {}
    @errors = {}
    @deleted = []
  end

  def run(memory)
    memory.hash[:remote_ids] = @remote_ids
    memory.hash[:outputs] = @outputs
    memory.hash[:errors] = @errors
    memory.hash[:deleted] = @deleted
    memory.hash[:temp] = {}
  end
end

# instruction to create
class CreateInstruction < Instruction
  def initialize(resource_name, resource_desc, properties)
    @resource_name = resource_name
    @resource_desc = resource_desc
    @properties = properties
  end

  def run(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(nil)
    resource.create(@properties)

    return unless @resource_desc.needs_remote_id?

    memory.hash[:remote_ids][@resource_name] = resource.remote_id
  end
end

# General checking class
class CheckInstruction < Instruction
  def initialize(resource_name, resource_desc, check_type)
    @resource_name = resource_name
    @resource_desc = resource_desc
    @check_type = check_type
  end

  def run(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])

    if resource.send(:"#{@check_type}_complete?")
      after_complete(memory)
    else
      # repeat this instruction until its done
      memory.program_counter -= 1
    end
  end

  def after_complete(_memory); end
end

# instruction to check create
class CheckCreateInstruction < CheckInstruction
  def initialize(resource_name, resource_desc)
    @resource_name = resource_name
    @resource_desc = resource_desc
    super(resource_name, resource_desc, :create)
  end

  def after_complete(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])

    return unless @resource_desc.output_fields.count

    memory.hash[:outputs][@resource_name] = resource.outputs
  end
end

# instruction to delete
class DeleteInstruction < Instruction
  def initialize(resource_name, resource_desc)
    @resource_name = resource_name
    @resource_desc = resource_desc
  end

  def run(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])
    resource.delete
  end
end

# check that delete is completed
class CheckDeleteInstruction < CheckInstruction
  def initialize(resource_name, resource_desc)
    @resource_name = resource_name
    @resource_desc = resource_desc
    super(resource_name, resource_desc, :delete)
  end

  def after_complete(memory)
    memory.hash[:deleted] << @resource_name

    return unless @resource_desc.needs_remote_id?

    memory.hash[:remote_ids].delete(@resource_name)
  end
end

# read properties of resource
class ReadInstruction < Instruction
  def initialize(resource_name, resource_desc, prop_list)
    @resource_name = resource_name
    @resource_desc = resource_desc
    @prop_list = prop_list
  end

  def run(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])
    memory.hash[:temp][@resource_name] = resource.read(@prop_list)
  end
end

# update a resource
class UpdateInstruction < Instruction
  def initialize(resource_name, resource_desc, properties)
    @resource_name = resource_name
    @resource_desc = resource_desc
    @properties = properties
  end

  def run(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])
    resource.update(@properties)
  end
end

# check that update is completed
class CheckUpdateInstruction < CheckInstruction
  def initialize(resource_name, resource_desc)
    @resource_name = resource_name
    @resource_desc = resource_desc
    super(resource_name, resource_desc, :update)
  end

  def after_complete(memory)
    resource_class = @resource_desc.resource_class
    resource = resource_class.new(memory.hash[:remote_ids][@resource_name])

    return unless @resource_desc.output_fields.count

    memory.hash[:outputs][@resource_name] = resource.outputs
  end
end

# memory that can be manipulated by instructions
class Memory
  attr_accessor :program_counter, :hash

  def initialize
    @program_counter = 0
    @hash = {}
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
    @memory.program_counter >= @instruction_list.length
  end

  def run_next
    return if ended?

    @instruction_list[@memory.program_counter].run(@memory)
    @memory.program_counter += 1
  end
end
