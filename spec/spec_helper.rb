# frozen_string_literal: true

require 'yaml'
require 'pry'
require 'singleton'
require 'tataru'
require 'active_support/testing/time_helpers'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end

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
    raise "Cannot delete while connected to #{ip}" unless ip.nil?

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
    raise "Nonexistent IP #{addr}" unless @ip_addresses.key? addr

    @ip_addresses[addr] = server_id
    @server_to_ip_map[server_id] = addr
  end

  def delete_ip(addr)
    raise "Nonexistent IP #{addr}" unless @ip_addresses.key? addr

    server_id = @ip_addresses[addr]
    @server_to_ip_map.delete(server_id)
    @ip_addresses.delete(addr)
  end
end

# base class of resource
class TestFileResource < Tataru::BaseResource
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

  def exist?
    TestEnvironment.instance.exists_file?(@remote_id)
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
class TestFileResourceDesc < Tataru::BaseResourceDesc
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
    %i[created_at updated_at]
  end

  def needs_remote_id?
    true
  end

  def delete_at_end?
    false
  end
end

# base class of resource
class TestServerResource < Tataru::BaseResource
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

  def update(params); end

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
class TestServerResourceDesc < Tataru::BaseResourceDesc
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
class StringJoinerResource < Tataru::BaseResource
  attr_reader :remote_id

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
class StringJoinerResourceDesc < Tataru::BaseResourceDesc
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

class TestIpAddressResource < Tataru::BaseResource
  def create(params)
    ip = TestEnvironment.instance.create_ip(params[:server_id])
    @remote_id = ip
  end

  def read(_name_array)
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

class TestIpAddressResourceDesc < Tataru::BaseResourceDesc
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
