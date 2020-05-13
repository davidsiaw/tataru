# frozen_string_literal: true

module Tataru
  module Instructions
    # compares resource in temp and resource in top
    class RescmpInstruction < ResourceInstruction
      include RomReader

      def run
        raise 'Not found' unless rom.key? resource_name

        update!
      end

      def update!
        current = memory.hash[:temp][resource_name]
        desired = resolve(rom[resource_name])

        memory.hash[:update_action][resource_name] = compare(current, desired)
      end

      def compare(current, desired)
        result = :no_change
        desc.mutable_fields.each do |field|
          result = :modify if current[field] != desired[field]
        end
        desc.immutable_fields.each do |field|
          result = :recreate if current[field] != desired[field]
        end
        result
      end
    end
  end
end
