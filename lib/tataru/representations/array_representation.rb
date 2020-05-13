# frozen_string_literal: true

module Tataru
  module Representations
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
  end
end
