# frozen_string_literal: true

module Tataru
  # human representation of resources
  class TopDsl
    attr_reader :resources

    def initialize(pool)
      @resources = {}
      @pool = pool
    end

    def resource(symbol, name, &block)
      raise "no such resource: #{symbol}" unless @pool.resource_desc_exist?(symbol)
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
end
