# frozen_string_literal: true

# base class of resource
class BaseResource
  attr_reader :remote_id

  def initialize(remote_id)
    @remote_id = remote_id
  end

  def create(name_value_hash)
    # create the resource
  end

  def read(name_array)
    # read a range of resource fields
  end

  def update(name_value_hash)
    # update the resource fields
  end

  def delete
    # delete the resource
  end

  def create_complete?
    # check if creation is complete
  end

  def update_complete?
    # check if update is complete
  end

  def delete_complete?
    # check if delete is complete
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

# a thing to do
class Instruction
  attr_reader :output, :error

  def initialize(operand)
    @operand = operand
  end

  def run(resource)
    @output = execute(resource)
  rescue StandardError => e
    @error = e
  end

  def execute(_resource)
    raise 'not implemented'
  end
end

# an instruction
class CreateInstruction < Instruction
  def execute(resource)
    resource.create
  end
end

# a quest
class Quest
  def initialize(resource_descs, instruction_hash)
    @resource_descs = resource_descs
    @instruction_hash = instruction_hash
  end

  def instruction_list
    [] # list of instructions
  end
end

# thing that runs a quest
class Adventurer
  attr_reader :outputs

  def initialize(quest)
    @quest = quest
    @outputs = {}
  end
end
