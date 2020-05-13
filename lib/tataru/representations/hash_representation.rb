# frozen_string_literal: true

module Tataru
  module Representations
    # representing hashes
    class HashRepresentation < Representation
      def initialize(value)
        @value = value.map do |key, thing|
          [key, Resolver.new(thing).representation]
        end.to_h
      end

      def dependencies
        @dependencies ||= @value.flat_map do |_key, rep|
          rep.dependencies
        end
      end
    end
  end
end
