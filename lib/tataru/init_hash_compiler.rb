# frozen_string_literal: true

module Tataru
  # compiles the inithash
  class InitHashCompiler
    def initialize(dsl)
      @dsl = dsl
    end

    def resolved_references(resource_name, references)
      references.map do |field, refname|
        [field, refname.to_s.sub(/^top/, resource_name)]
      end.to_h
    end

    def generate_init_hash
      rom = {}
      @dsl.resources.each do |k, v|
        # Expand all the values used to a big flat hash that
        # is only one level deep for ease of use, then mark
        # them for the vm to use
        flattener = Flattener.new(v)
        flattener.flattened.each do |key, value|
          fixed = value.dup
          if fixed[:references]
            fixed[:references] = resolved_references(k, fixed[:references])
          end
          rom[key.to_s.sub(/^top/, k)] = fixed
        end
      end
      {
        rom: rom,
        remote_ids: {}
      }
    end

    def result
      @result ||= generate_init_hash
    end
  end
end
