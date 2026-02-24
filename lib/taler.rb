# frozen_string_literal: true

require_relative "taler/client"
require_relative "taler/order"
require_relative "taler/version"

# GNU Taler payment system interface
module Taler
  # Base error class for errors raised in this module
  class Error < StandardError; end
end
