# frozen_string_literal: true

module Tataru
  # resolver for data
  class Resolver
    def initialize(expression)
      @expression = expression
    end

    def representation
      @representation ||= generate_representation
    end

    def dependencies
      representation.dependencies
    end

    private

    def generate_representation
      case @expression
      when String
        Representations::LiteralRepresentation.new(@expression)
      when Numeric
        Representations::LiteralRepresentation.new(@expression)
      when Array
        Representations::ArrayRepresentation.new(@expression)
      when Hash
        Representations::HashRepresentation.new(@expression)
      when Representations::ResourceRepresentation
        @expression
      when Representations::OutputRepresentation
        @expression
      else
        raise "invalid value: #{@expression.inspect}"
      end
    end
  end
end
