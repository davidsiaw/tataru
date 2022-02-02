# frozen_string_literal: true

module Tataru
  # returns subroutines required based on the resource
  class SubPlanner
    def initialize(rrep, action, create_missing)
      @rrep = rrep
      @action = action
      @create_missing = create_missing
    end

    def name
      @rrep.name
    end

    def compile(*args)
      SubroutineCompiler.new(@rrep, @create_missing, *args)
    end

    def extra_subroutines
      return {} unless @action == :update

      {
        "#{name}_modify" => compile(:modify),
        "#{name}_modify_check" => compile(:modify_check),
        "#{name}_recreate" => compile(:recreate),
        "#{name}_recreate_check" => compile(:recreate_check),
        "#{name}_recreate_commit" => compile(:recreate_commit),
        "#{name}_recreate_finish" => compile(:recreate_finish),
        "#{name}_missing_create" => compile(:missing_create),
        "#{name}_missing_create_check" => compile(:missing_create_check)
      }
    end

    def subroutines
      {
        "#{name}_start" => compile(:"#{@action}"),
        "#{name}_check" => compile(:"check_#{@action}"),
        "#{name}_commit" => compile(:"commit_#{@action}"),
        "#{name}_finish" => compile(:"finish_#{@action}")
      }.merge(extra_subroutines)
    end
  end
end
