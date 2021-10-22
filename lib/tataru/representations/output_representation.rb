# frozen_string_literal: true

module Tataru
  module Representations
    # internal representation of output
    class OutputRepresentation < Representation
      attr_reader :resource_name, :output_field_name

      def initialize(resource_name, output_field_name)
        @resource_name = resource_name
        @output_field_name = output_field_name
        super(nil)
      end

      def dependencies
        [@resource_name]
      end
    end
  end
end
