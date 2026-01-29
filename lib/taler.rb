# frozen_string_literal: true

require_relative "taler/client"
require_relative "taler/order"
require_relative "taler/version"

module Taler
  class Error < StandardError; end
end
