# frozen_string_literal: true

module Tataru
  # base representation
  class Representation
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def dependencies
      []
    end
  end
end

require 'tataru/representations/hash_representation'
require 'tataru/representations/array_representation'
require 'tataru/representations/literal_representation'
require 'tataru/representations/output_representation'
require 'tataru/representations/resource_representation'
