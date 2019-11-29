# frozen_string_literal: true

module Tataru
  # base resource class
  class Resource
    class << self
      def state(state_name, change_behaviour)
        define_method "#{state_name}_change_action" do
          change_behaviour
        end

        define_method "_state_#{state_name}" do
          state_name
        end
      end

      def output(output_name)
        define_method "_output_#{output_name}" do
          output_name
        end

        define_method(output_name) {}
      end
    end

    def states
      list_props(:state)
    end

    def outputs
      list_props(:output)
    end

    def create; end

    def update; end

    def delete; end

    private

    def list_props(prop_type)
      methods.select { |x| x.to_s.start_with? "_#{prop_type}_" }
             .map { |x| x.to_s.sub("_#{prop_type}_", '').to_sym }
    end
  end
end
