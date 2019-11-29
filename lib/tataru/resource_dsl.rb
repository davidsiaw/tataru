# frozen_string_literal: true

module Tataru
  module DoLater
    # delayed expression
    class Expression
      def requested_resources
        raise 'Abstract class'
      end
    end

    # placeholder for extern resource
    class ExternResourcePlaceholder < Expression
      def initialize(name)
        @name = name
      end

      def respond_to_missing?
        true
      end

      def method_missing(name, *_args)
        super if name.nil?

        MemberCallPlaceholder.new(self, name)
      end

      def requested_resources
        [@name]
      end
    end

    # placeholder for member call
    class MemberCallPlaceholder < ExternResourcePlaceholder
      def initialize(expr, member)
        @expr = expr
        @member = member
      end

      def requested_resources
        @expr.requested_resources
      end
    end
  end

  # Resource DSL
  class ResourceDSL
    attr_reader :fields, :extern_refs

    def initialize(resource_inst)
      @resource_inst = resource_inst
      @fields = {}
      @extern_refs = {}
    end

    def respond_to_missing?
      true
    end

    def method_missing(name, *args, &block)
      if @resource_inst.respond_to?("#{name}_change_action")
        @fields[name] = args[0]
      elsif name.to_s.start_with?(/[a-z]/)
        @extern_refs[name] ||= DoLater::ExternResourcePlaceholder.new(name)
      else
        super
      end
    end

    def errors
      (@resource_inst.states - @fields.keys).map do |x|
        { missing_state: x }
      end
    end

    def dependencies
      deps = []
      @fields.each do |_name, info|
        next unless info.is_a? DoLater::Expression

        deps += info.requested_resources
      end
      deps.map(&:to_s).uniq
    end
  end
end
