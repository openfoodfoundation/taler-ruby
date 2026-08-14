# frozen_string_literal: true

require_relative "taler/client"
require_relative "taler/order"
require_relative "taler/version"

# GNU Taler payment system interface
module Taler
  # Base error class for errors raised in this module
  class Error < StandardError; end

  # Raised when the merchant backend answers with an unexpected status code.
  class RequestError < Error
    # @return [Integer] The HTTP status code of the response.
    attr_reader :status

    # @return [String] The raw response body.
    attr_reader :body

    # @param message [String]
    # @param status [Integer]
    # @param body [String]
    def initialize(message, status:, body:)
      super(message)
      @status = status
      @body = body
    end
  end

  # Raised when the backend wants multi-factor authentication before it
  # performs the requested operation.
  #
  # The backend answers with `202 Accepted` and a list of challenges. Each
  # challenge has to be requested and then solved with a TAN sent to the
  # instance owner. Solving challenges is not supported by this gem yet.
  #
  # Only account management endpoints require MFA. Most notably, requesting
  # an access token may be challenged while the order endpoints never are.
  # So you can avoid this error by authenticating with the instance password
  # instead of an access token, which is the default.
  #
  # See: https://docs.taler.net/core/api-merchant.html#two-factor-auth
  class ChallengeRequired < RequestError
    # @return [Array<Hash>] The challenges to solve. Each one has a
    #   `challenge_id`, a `tan_channel` and a `tan_info` hint.
    attr_reader :challenges

    # @return [Boolean] True if *all* challenges have to be solved, false if
    #   it is sufficient to solve one of them.
    attr_reader :combi_and

    # @param message [String]
    # @param status [Integer]
    # @param body [String]
    # @param challenges [Array<Hash>]
    # @param combi_and [Boolean]
    def initialize(message, status:, body:, challenges: [], combi_and: false)
      super(message, status:, body:)
      @challenges = challenges
      @combi_and = combi_and
    end
  end
end
