# frozen_string_literal: true

module Tataru
  module Representations
    # representing hashes
    class HashRepresentation < Representation
      def initialize(value)
        super(@value = value.transform_values do |thing|
          Resolver.new(thing).representation
        end)
      end

      def dependencies
        @dependencies ||= @value.flat_map do |_key, rep|
          rep.dependencies
        end
      end
    end
  end
end
