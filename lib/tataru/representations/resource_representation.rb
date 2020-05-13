# frozen_string_literal: true

module Tataru
  module Representations
    # internal representation of resources
    class ResourceRepresentation < Representation
      attr_reader :name, :properties, :desc

      def initialize(name, desc, properties)
        @name = name
        @properties = properties
        @desc = desc
        check_late_deletability!
      end

      def check_late_deletability!
        return unless @desc.delete_at_end? && !@desc.needs_remote_id?

        raise 'must need remote id if deletes at end'
      end

      def check_required_fields!
        @desc.required_fields.each do |field|
          next if @properties.key? field

          raise "Required field '#{field}' not provided in '#{@name}'"
        end
      end

      def respond_to_missing?(name, *_args)
        true if @desc.output_fields.include? name
      end

      def remote_id
        OutputRepresentation.new(@name, :remote_id)
      end

      def method_missing(name, *args, &block)
        return super unless @desc.output_fields.include? name

        OutputRepresentation.new(@name, name)
      end

      def dependencies
        [@name]
      end
    end
  end
end
