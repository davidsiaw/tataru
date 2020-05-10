# frozen_string_literal: true

require 'tataru'

class TestEnvironment
  include Singleton

  attr_accessor :files, :servers, :ip_addresses

  def initialize
    clear!
  end

  def clear!
    # ids decided by user
    @domain_names = {}
    # a resource with mutable fields
    @load_balancers = {}
    # a resource with outputs
    @api_keys = {}

    # a resource
    @files = {}
    # a resource that overlaps
    @servers = []

    # ids decided by server
    @ip_addresses = {}
    @server_to_ip_map = {}
  end

  def create_file(name, contents)
    raise 'Duplicate file name' if @files.key? name

    @files[name] = {
      name: name,
      contents: contents,
      updated_at: Time.now.utc.to_s,
      created_at: Time.now.utc.to_s
    }
  end

  def update_file(name, contents)
    raise "Nonexistent file '#{name}'" unless @files.key? name

    @files[name][:contents] = contents
    @files[name][:updated_at] = Time.now.utc.to_s
  end

  def delete_file(name)
    raise "Nonexistent file '#{name}'" unless @files.key? name

    @files.delete name
  end

  def exists_file?(name)
    @files.key? name
  end

  def file(name)
    raise "Nonexistent file '#{name}'" unless @files.key? name

    @files[name]
  end


  def create_server(size)
    id = @servers.count
    @servers[id] = {
      size: size,
      created_at: Time.now.utc.to_s
    }
    "server#{id}"
  end

  def delete_server(server_id)
    id = server_id.sub(/^server/, '').to_i
    raise "Nonexistent server '#{server_id}'" if @servers[id].nil?

    ip = @server_to_ip_map[server_id]
    if ip != nil
      raise "Cannot delete while connected to #{ip}"
    end

    @servers[id] = nil
  end

  def exists_server?(server_id)
    id = server_id.sub(/^server/, '').to_i
    @servers.key? id
  end

  def server(server_id)
    id = server_id.sub(/^server/, '').to_i
    raise "Nonexistent server '#{server_id}'" if @servers[id].nil?

    @servers[id]
  end

  def create_ip(server_id)
    id = server_id.sub(/^server/, '').to_i
    raise "Nonexistent server '#{server_id}'" if @servers[id].nil?

    (2..254).each do |i|
      addr = "2.3.4.#{i}"
      next if @ip_addresses.key? addr

      return modify_ip(addr, server_id)
    end

    raise 'No more ips available'
  end

  def modify_ip(addr, server_id)
    id = server_id.sub(/^server/, '').to_i
    raise "Nonexistent server '#{server_id}'" if @servers[id].nil?
    raise "Nonexistent IP #{addr}" if !@ip_addresses.key? addr

    @ip_addresses[addr] = server_id
    @server_to_ip_map[server_id] = addr
  end

  def delete_ip(addr)
    raise "Nonexistent IP #{addr}" if !@ip_addresses.key? addr

    server_id = @ip_addresses[addr]
    @server_to_ip_map.delete(server_id)
    @ip_addresses.delete(addr)
  end
end

# base class of resource
class TestFileResource < BaseResource
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
    TestEnvironment.instance.update_file(@remote_id, params[:contents])
  end

  def delete
    TestEnvironment.instance.delete_file(@remote_id)
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

# base class of resource
class TestServerResource < BaseResource
  def create(params)
    @remote_id = TestEnvironment.instance.create_server(params[:size])
  end

  def read(name_array)
    results = {}
    TestEnvironment.instance.server(@remote_id).each do |k, v|
      results[k] = v if name_array.include? k
    end
    results
  end

  def update(params)
  end

  def delete
    TestEnvironment.instance.delete_server(@remote_id)
  end

  def outputs
    TestEnvironment.instance.server(@remote_id)
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
class TestServerResourceDesc < BaseResourceDesc
  def resource_class
    TestServerResource
  end

  def mutable_fields
    []
  end

  def immutable_fields
    [:size]
  end

  def required_fields
    [:size]
  end

  def output_fields
    [:created_at]
  end

  def needs_remote_id?
    true
  end

  def delete_at_end?
    true
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

class TestIpAddressResource < BaseResource
  def create(params)
    ip = TestEnvironment.instance.create_ip(params[:server_id])
    @remote_id = ip 
  end

  def read(name_array)
    {
      server_id: TestEnvironment.instance.ip_addresses[@remote_id]
    }
  end

  def update(params)
    TestEnvironment.instance.modify_ip(@remote_id, params[:server_id])
  end

  def delete
    TestEnvironment.instance.delete_ip(@remote_id)
  end

  def outputs
    {
      server_id: TestEnvironment.instance.ip_addresses[@remote_id]
    }
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

class TestIpAddressResourceDesc < BaseResourceDesc
  def resource_class
    TestIpAddressResource
  end

  def mutable_fields
    [:server_id]
  end

  def immutable_fields
    []
  end

  def required_fields
    [:server_id]
  end

  def output_fields
    [:ip]
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
    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'something1.txt' => {
        name: 'something1.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'something1.txt'
  end

  it 'builds and deletes one resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'something1.txt' => {
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file1' => {
        name: 'something1.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file2' do
        name 'something2.txt'
        contents '123'
      end
    end

    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'something2.txt' => {
        name: 'something2.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file2']).to eq 'something2.txt'
  end

  it 'builds and deletes one overlapping resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.servers = [
      {
        size: 'BIG',
        created_at: "2010-01-01 00:00:00 UTC"
      }
    ]

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    rtp.add_resource_desc(:server, TestServerResourceDesc)
    remote_ids = {
      'oldserv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru.new(rtp, remote_ids)
    ttr.construct do
      s = resource :server, 'serv' do
        size 'SMOL'
      end

      resource :file, 'file1' do
        name 'something2.txt'
        contents s.created_at
      end
    end

    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.servers).to eq [
      nil,
      {
        size: 'SMOL',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(runner.memory.hash[:remote_ids]['serv']).to eq 'server1'
  end

  it 'performs mutable update' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'ddd.txt' => {
        name: 'ddd.txt',
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file' => {
        name: 'ddd.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file' do
        name 'ddd.txt'
        contents '123'
      end
    end

    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'ddd.txt' => {
        name: 'ddd.txt',
        contents: '123',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'ddd.txt'
  end

  it 'performs immutable update' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.files = {
      'ggg.txt' => {
        name: 'ggg.txt',
        contents: 'asd',
        created_at: "2010-01-01 00:00:00 UTC",
        updated_at: "2010-01-01 00:00:00 UTC"
      }
    }

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:file, TestFileResourceDesc)
    remote_ids = {
      'file' => {
        name: 'ggg.txt',
        desc: 'TestFileResourceDesc',
        dependencies: []
      }
    }

    ttr = Tataru.new(rtp, remote_ids)
    ttr.construct do
      resource :file, 'file' do
        name 'fff.txt'
        contents '123'
      end
    end

    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    travel_to Time.new(2011, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end
    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.files).to eq(
      'fff.txt' => {
        name: 'fff.txt',
        contents: '123',
        created_at: "2011-01-01 00:00:00 UTC",
        updated_at: "2011-01-01 00:00:00 UTC"
      }
    )

    expect(runner.memory.hash[:remote_ids]['file']).to eq 'fff.txt'
  end

  it 'recreates an overlapping resource' do
    TestEnvironment.instance.clear!

    TestEnvironment.instance.servers = [
      {
        size: 'A',
        created_at: "2010-01-01 00:00:00 UTC"
      }
    ]

    TestEnvironment.instance.ip_addresses = {
      '2.3.4.2' => 'server0'
    }

    rtp = ResourceTypePool.new
    rtp.add_resource_desc(:ip_address, TestIpAddressResourceDesc)
    rtp.add_resource_desc(:server, TestServerResourceDesc)
    remote_ids = {
      'serv' => {
        name: 'server0',
        desc: 'TestServerResourceDesc',
        dependencies: []
      },
      'ip' => {
        name: '2.3.4.2',
        desc: 'TestIpAddressResourceDesc',
        dependencies: ['serv']
      }
    }

    ttr = Tataru.new(rtp, remote_ids)
    ttr.construct do
      s = resource :server, 'serv' do
        size 'B'
      end

      resource :ip_address, 'ip' do
        server_id s
      end
    end

    ih = InstructionHash.new(ttr.instr_hash)
    runner = Runner.new(ih.instruction_list)

    puts ttr.instr_hash.to_yaml

    travel_to Time.new(2015, 1, 1, 0, 0, 0, '+00:00') do
      loop do
        runner.run_next
        break if runner.ended?
      end
    end

    #puts runner.memory.error.backtrace.to_yaml

    expect(runner.memory.error).to be_nil
    expect(TestEnvironment.instance.servers).to eq [
      nil,
      {
        size: 'B',
        created_at: "2015-01-01 00:00:00 UTC"
      }
    ]

    expect(TestEnvironment.instance.ip_addresses).to eq(
      '2.3.4.2' => 'server1'
    )

    expect(runner.memory.hash[:remote_ids]['serv']).to eq 'server1'
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
    travel_to Time.new(2012, 1, 1, 0, 0, 0, '+00:00') do
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
      contents: "2012-01-01 00:00:00 UTC\n2012-01-01 00:00:00 UTC"
    )
    expect(runner.memory.hash[:remote_ids]['f1']).to eq 'something1.txt'
    expect(runner.memory.hash[:remote_ids]['f2']).to eq 'something2.txt'
    expect(runner.memory.hash[:remote_ids]['cdates']).to eq 'creationdates.txt'
  end
end
