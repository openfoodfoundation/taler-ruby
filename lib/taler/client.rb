# frozen_string_literal: true

require "json"
require "net/http"

module Taler
  # Access the GNU Taler merchant backend API.
  #
  # See: https://docs.taler.net/core/api-merchant.html
  class Client
    # @param backend_url [String] e.g. `"https://backend.demo.taler.net/instances/sandbox"`
    # @param password [String]
    def initialize(backend_url, password)
      @backend_url = backend_url
      @password = password
    end

    # Obtain an access token to authenticate all other API calls.
    #
    # @return [String]
    def request_token
      url = "#{@backend_url}/private/token"
      payload = {scope: "write"}
      result = request(url, token: auth_token, payload:)
      result.fetch("token")
    end

    # @param amount [String] e.g. "KUDOS:200"
    # @param summary [String] A description of the order displayed to the user.
    # @param fulfillment_url [String] The user is redirected to this URL after
    #   payment. The order status page also links here.
    # @param fulfillment_message [String] Text to display to the user after
    #   payment.
    # @return [Hash] The resonse from the backend, usually just containing an
    #   order id, e.g. `{order_id: "xxxxx"}`
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
    def fetch_order(order_id)
      url = "#{@backend_url}/private/orders/#{order_id}"
      request(url)
    end

    # @param order_id [String]
    # @param refund [String] The amount with currency.
    # @param reason [String] Why are you refunding?
    #
    # @return [Hash] Response from the merchant backend.
    def refund_order(order_id, refund:, reason:)
      url = "#{@backend_url}/private/orders/#{order_id}/refund"
      payload = {refund:, reason:}
      request(url, payload:)
    end

    private

    # @return [String]
    def auth_token
      "secret-token:#{@password}"
    end

    # @param url [String]
    # @param token [String]
    # @param payload [Hash]
    # @return [String]
    def request(url, token: auth_token, payload: nil)
      uri = URI(url)
      headers = {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "User-Agent" => "Taler Ruby"
      }

      if payload.nil?
        body = Net::HTTP.get(uri, headers)
      else
        headers["Content-Type"] = "application/json"
        data = JSON.dump(payload)
        response = Net::HTTP.post(uri, data, headers)
        body = response.body
      end

      JSON.parse(body)
    end
  end
end
