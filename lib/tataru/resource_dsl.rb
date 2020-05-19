# frozen_string_literal: true

module Tataru
  # human representation of resources
  class ResourceDsl
    REPCLASS = Tataru::Representations::ResourceRepresentation

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
      @properties[name] = if resolver.representation.is_a? REPCLASS
                            resolver.representation.remote_id
                          else
                            resolver.representation
                          end
    end

    def representation
      REPCLASS.new(@name, @desc, @properties)
    end
  end
end
