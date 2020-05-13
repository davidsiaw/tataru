# frozen_string_literal: true

module Tataru
  # flattens properties to make them digestable
  class Flattener
    def initialize(value)
      @value = value
      @result = {}
    end

    def flattened
      flatten(@value, :top)
      @result
    end

    def flatten(value, name)
      type = value.class.name.sub(/^Tataru::Representations::/, '').sub(/Representation$/, '').downcase
      method_name = :"flatten_#{type}"
      raise "cannot flatten #{value.inspect}" unless respond_to?(method_name)

      send(method_name, value, name)
    end

    def flatten_literal(value, name)
      @result[name] = {
        type: :literal,
        value: value.value
      }
    end

    def flatten_array(value, name)
      refs = {}
      value.value.each_with_index do |val, i|
        key = :"#{name}_#{i}"
        flatten(val, key)
        refs[i] = key
      end
      @result[name] = {
        type: :array,
        references: refs
      }
    end

    def flatten_hash(value, name)
      refs = {}
      value.value.each do |k, v|
        key = :"#{name}_#{k}"
        flatten(v, key)
        refs[k] = key
      end
      @result[name] = {
        type: :hash,
        references: refs
      }
    end

    def flatten_resource(value, name)
      refs = {}
      value.properties.each do |k, v|
        key = :"#{name}_#{k}"
        flatten(v, key)
        refs[k] = key
      end
      @result[name] = {
        type: :hash,
        references: refs
      }
    end

    def flatten_output(value, name)
      @result[name] = {
        type: :output,
        resource: value.resource_name,
        output: value.output_field_name
      }
    end
  end
end
