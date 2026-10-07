# frozen_string_literal: true

require_relative "taler/client"
require_relative "taler/order"
require_relative "taler/version"

# GNU Taler payment system interface
module Taler
  # Base error class for errors raised in this module
  class Error < StandardError; end

  # Raised when the merchant backend answers with anything but 200 OK.
  #
  # The backend explains errors with a JSON body like
  # `{"code": 2015, "hint": "...", "detail": "..."}`. The hint is used
  # as the error message. A body that is not JSON, like an HTML page
  # from a proxy, is kept as text.
  class RequestError < Error
    # @return [Integer] The HTTP status code of the response.
    attr_reader :status

    # @return [Hash, String] The parsed JSON body or the raw body.
    attr_reader :body

    # @param response [Net::HTTPResponse]
    def initialize(response)
      @status = response.code.to_i
      @body = error_body(response.body)
      super("The Taler backend responded with #{status}: #{summary}")
    end

    private

    # @return [String]
    def summary
      return body.fetch("hint") if body.is_a?(Hash) && body.key?("hint")

      body.to_s.strip
    end

    # @param body [String]
    # @return [Hash, String] The parsed JSON body, or the raw body if it isn't JSON.
    def error_body(body)
      JSON.parse(body)
    rescue JSON::ParserError
      body
    end
  end
end
