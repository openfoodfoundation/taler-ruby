# frozen_string_literal: true

require "json"
require "net/http"

module Taler
  # Access the GNU Taler merchant backend API.
  #
  # See: https://docs.taler.net/core/api-merchant.html
  class Client
    # @param backend_url [String] e.g. `"https://backend.demo.taler.net/instances/sandbox"`
    # @param password [String, nil] The instance password. It is used as
    #   authentication token for all requests unless an `access_token` is
    #   given.
    # @param access_token [String, nil] A token obtained from the
    #   `/private/token` endpoint, see {#request_token}. It has to include the
    #   `"secret-token:"` prefix. Given a token, the password isn't needed.
    # @raise [ArgumentError] If neither password nor access token are given.
    def initialize(backend_url, password = nil, access_token: nil)
      if password.nil? && access_token.nil?
        raise ArgumentError, "Provide a password or an access_token."
      end

      @backend_url = backend_url
      @password = password
      @access_token = access_token
    end

    # Obtain an access token to authenticate other API calls.
    #
    # This is optional. All requests authenticate with the instance password
    # by default. But an access token can be scoped and passed on to a less
    # trusted party without sharing the instance password.
    #
    # Beware that the backend may require multi-factor authentication for
    # this endpoint. It then answers with a list of challenges to solve and
    # this method raises {ChallengeRequired}. The order endpoints are never
    # challenged, so password authentication keeps working in that case.
    #
    # @param scope [String] Which kinds of operations the token allows, e.g.
    #   `"order-mgmt"` to create, read and refund orders. Tokens of the
    #   default `"all"` scope are always refreshable.
    # @param duration [Hash, nil] How long the token stays valid, e.g.
    #   `{d_us: 86_400_000_000}` for one day. The backend applies its own
    #   upper bound and its own default when this is omitted.
    # @return [String] The token including the `"secret-token:"` prefix.
    # @raise [ChallengeRequired] If the backend requires MFA.
    # @raise [RequestError] If the backend rejects the request.
    def request_token(scope: "all", duration: nil)
      url = "#{@backend_url}/private/token"
      payload = {scope:}
      payload[:duration] = duration unless duration.nil?
      result = request(url, token: password_token, payload:)

      # The `token` field is deprecated since merchant API v19.
      result["access_token"] || result.fetch("token")
    end

    # @param amount [String] e.g. "KUDOS:200"
    # @param summary [String] A description of the order displayed to the user.
    # @param fulfillment_url [String] The user is redirected to this URL after
    #   payment. The order status page also links here.
    # @param fulfillment_message [String] Text to display to the user after
    #   payment.
    # @return [Hash] The resonse from the backend, usually just containing an
    #   order id, e.g. `{order_id: "xxxxx"}`
    # @raise [RequestError] If the backend rejects the request.
    def create_order(amount:, summary:, fulfillment_url: nil, fulfillment_message: nil)
      url = "#{@backend_url}/private/orders"
      order = {
        amount: amount,
        summary: summary
      }
      order[:fulfillment_url] = fulfillment_url unless fulfillment_url.nil?
      order[:fulfillment_message] = fulfillment_message unless fulfillment_message.nil?
      payload = {order:, create_token: false}
      request(url, payload:)
    end

    # @param order_id [String]
    # @return [String]
    def order_status_url(order_id)
      "#{@backend_url}/orders/#{order_id}"
    end

    # @param order_id [String]
    # @return [Hash] The order status returned by the backend.
    # @raise [RequestError] If the backend rejects the request.
    def fetch_order(order_id)
      url = "#{@backend_url}/private/orders/#{order_id}"
      request(url)
    end

    # @param order_id [String]
    # @param refund [String] The amount with currency.
    # @param reason [String] Why are you refunding?
    #
    # @return [Hash] Response from the merchant backend.
    # @raise [RequestError] If the backend rejects the request.
    def refund_order(order_id, refund:, reason:)
      url = "#{@backend_url}/private/orders/#{order_id}/refund"
      payload = {refund:, reason:}
      request(url, payload:)
    end

    private

    # The instance password in the format of an authentication token.
    #
    # This is deprecated since merchant API v19 but still the simplest way to
    # authenticate. It works on all endpoints and is never challenged for
    # multi-factor authentication.
    #
    # @return [String]
    def password_token
      "secret-token:#{@password}"
    end

    # @return [String]
    def auth_token
      @access_token || password_token
    end

    # @param url [String]
    # @param token [String]
    # @param payload [Hash, nil] Sent as JSON body of a POST request. Without
    #   a payload, a GET request is sent.
    # @return [Hash] The parsed response body.
    # @raise [ChallengeRequired] If the backend requires MFA.
    # @raise [RequestError] If the backend answers with an error status.
    def request(url, token: auth_token, payload: nil)
      uri = URI(url)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
        http.request(build_request(uri, token, payload))
      end

      parse(response)
    end

    # @param uri [URI]
    # @param token [String]
    # @param payload [Hash, nil]
    # @return [Net::HTTPRequest]
    def build_request(uri, token, payload)
      headers = {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "User-Agent" => "Taler Ruby"
      }

      return Net::HTTP::Get.new(uri, headers) if payload.nil?

      headers["Content-Type"] = "application/json"
      Net::HTTP::Post.new(uri, headers).tap do |request|
        request.body = JSON.dump(payload)
      end
    end

    # @param response [Net::HTTPResponse]
    # @return [Hash] The parsed response body.
    # @raise [ChallengeRequired] If the backend requires MFA.
    # @raise [RequestError] If the backend answers with an error status.
    def parse(response)
      status = response.code.to_i
      body = response.body.to_s

      # A 202 is a success status but it doesn't contain what we asked for.
      raise challenge_error(status, body) if status == 202

      unless response.is_a?(Net::HTTPSuccess)
        raise RequestError.new(
          "The Taler backend responded with #{status}: #{summarise(body)}",
          status:, body:
        )
      end

      JSON.parse(body)
    end

    # @param status [Integer]
    # @param body [String]
    # @return [ChallengeRequired]
    def challenge_error(status, body)
      challenge = begin
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
      challenges = challenge["challenges"] || []
      channels = challenges.filter_map { |c| c["tan_channel"] }.join(", ")

      ChallengeRequired.new(
        "The Taler backend requires multi-factor authentication" \
        "#{" via #{channels}" unless channels.empty?}. " \
        "Solving challenges is not supported. " \
        "Authenticate with the instance password instead of an access token.",
        status:,
        body:,
        challenges:,
        combi_and: challenge["combi_and"] || false
      )
    end

    # Error bodies can be long, especially when a proxy returns HTML.
    #
    # @param body [String]
    # @return [String]
    def summarise(body)
      (body.length > 500) ? "#{body[0, 500]}..." : body
    end
  end
end
