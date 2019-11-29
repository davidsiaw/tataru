# frozen_string_literal: true

module Tataru
  # base resource class
  class Resource
    class << self
      def state(state_name, change_behaviour)
        define_method "#{state_name}_change_action" do
          change_behaviour
        end
      end
    end

    def create; end

    def update; end

    def delete; end
  end
end
