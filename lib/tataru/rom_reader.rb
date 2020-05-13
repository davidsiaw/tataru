# frozen_string_literal: true

module Tataru
  # Reads Rom values
  module RomReader
    def rom
      memory.hash[:rom]
    end

    def resolve(object)
      case object[:type]
      when :literal
        object[:value]
      when :hash
        resolve_hash(object)
      when :array
        resolve_array(object)
      when :output
        resolve_output(object)
      end
    end

    def resolve_array(object)
      result = []
      object[:references].each do |k, v|
        result[k] = resolve(rom[v])
      end
      result
    end

    def resolve_hash(object)
      result = {}
      object[:references].each do |k, v|
        result[k] = resolve(rom[v])
      end
      result
    end

    def resolve_output(object)
      if object[:output] == :remote_id
        memory.hash[:remote_ids][object[:resource]]
      else
        memory.hash[:outputs][object[:resource]][object[:output]]
      end
    end
  end
end
