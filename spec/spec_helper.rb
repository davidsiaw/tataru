# frozen_string_literal: true

require 'yaml'
require 'pry'
require 'active_support/testing/time_helpers'

RSpec.configure do |config|
  config.include ActiveSupport::Testing::TimeHelpers
end
