# frozen_string_literal: true

require 'tataru'

class TestEnvironment
  include Singleton

  def initialize
    clear!
  end

  def clear!
    # ids decided by server
    @ip_addresses = {}
    # ids decided by user
    @domain_names = {}
    # a resource with mutable fields
    @load_balancers = {}
    # a resource with immutable fields that do overlap
    @servers = {}
    # a resource with outputs
    @api_keys = {}

    # a complex resource
    @files = {}
  end

  def create_file(name, contents)
    raise 'Duplicate file name' if @files.key? name

    @files[name] = {
      contents: contents,
      updated_at: Time.now.to_s,
      created_at: Time.now.to_s
    }
  end

  def update_file(name, contents)
    raise 'Nonexistent file' unless @files.key? name

    @files[name][:contents] = contents
    @files[name][:updated_at] = Time.now.to_s
  end

  def delete_file(name)
    raise 'Nonexistent file' unless @files.key? name

    @files.delete name
  end

  def exists_file?(name)
    @files.key? name
  end

  def file(name)
    raise 'Nonexistent file' unless @files.key? name

    @files[name]
  end
end

# base class of resource
class TestFileResource < BaseResource
  attr_reader :remote_id

  def initialize(remote_id)
    @remote_id = remote_id
  end

  def create(params)
    TestEnvironment.instance.create_file(params[:name], params[:contents])
    @remote_id = params[:name]
  end

  def read(name_array)
    results = {}
    TestEnvironment.instance.file(@remote_id).each do |k, v|
      results[k] = v if name_array.include? k
    end
    results
  end

  def update(params)
    TestEnvironment.instance.update_file(params[:name], params[:contents])
  end

  def delete
    TestEnvironment.instance.delete_file(params[:name])
  end

  def outputs
    TestEnvironment.instance.file(@remote_id)
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
class TestFileResourceDesc < BaseResourceDesc
  def resource_class
    TestFileResource
  end

  def mutable_fields
    [:contents]
  end

  def immutable_fields
    [:name]
  end

  def required_fields
    [:name]
  end

  def output_fields
    [:created_at, :updated_at]
  end

  def needs_remote_id?
    true
  end

  def delete_at_end?
    false
  end
end

# string joiner
class StringJoinerResource < BaseResource
  attr_reader :remote_id

  def initialize(remote_id)
    @remote_id = remote_id
  end

  def create(params)
    @remote_id = params[:strings].join("\n")
  end

  def outputs
    {
      result: @remote_id
    }
  end
end

# description of a StringJoinerResource
class StringJoinerResourceDesc < BaseResourceDesc
  def resource_class
    StringJoinerResource
  end

  def immutable_fields
    [:strings]
  end

  def output_fields
    [:result]
  end

  def required_fields
    [:strings]
  end

  def needs_remote_id?
    true
  end

  def delete_at_end?
    false
  end
end

describe Tataru do
  it 'builds one resource' do
    TestEnvironment.instance.clear!

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    ttr = Tataru.new(rtp)
    ttr.construct do
      resource :file, 'file' do
        name 'something1.txt'
        contents '123'
      end
    end
    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)
    loop do
      runner.run_next
      break if runner.ended?
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.file('something1.txt')).to include(
      contents: '123'
    )
    expect(runner.memory.hash[:remote_ids]['file']).to eq 'something1.txt'
  end

  it 'builds multiple resources' do
    TestEnvironment.instance.clear!

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    rtp.add_resource_desc(:string_joiner, StringJoinerResourceDesc)

    ttr = Tataru.new(rtp)
    ttr.construct do
      r1 = resource :file, 'f1' do
        name 'something1.txt'
        contents 'meow'
      end

      r2 = resource :file, 'f2' do
        name 'something2.txt'
        contents 'woof'
      end

      sj = resource :string_joiner, 'joiner' do
        strings [r1.created_at, r2.created_at]
      end

      resource :file, 'cdates' do
        name 'creationdates.txt'
        contents sj.result
      end
    end
    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    #puts ttr.instr_hash.to_yaml
    travel_to Time.new(2012, 1, 1) do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil

    expect(TestEnvironment.instance.file('something1.txt')).to include(
      contents: 'meow'
    )
    expect(TestEnvironment.instance.file('something2.txt')).to include(
      contents: 'woof'
    )
    expect(TestEnvironment.instance.file('creationdates.txt')).to include(
      contents: "2012-01-01 00:00:00 +0900\n2012-01-01 00:00:00 +0900"
    )
    expect(runner.memory.hash[:remote_ids]['f1']).to eq 'something1.txt'
    expect(runner.memory.hash[:remote_ids]['f2']).to eq 'something2.txt'
    expect(runner.memory.hash[:remote_ids]['cdates']).to eq 'creationdates.txt'
  end
end
