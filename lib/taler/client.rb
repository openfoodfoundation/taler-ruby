# frozen_string_literal: true

require "json"
require "net/http"

module Taler
  # Access the GNU Taler merchant backend API.
  #
  # See: https://docs.taler.net/core/api-merchant.html
  class Client
    def initialize(backend_url, password)
      @backend_url = backend_url
      @password = password
    end

    def request_token
      url = "#{@backend_url}/private/token"
      payload = {scope: "write"}
      result = request(url, payload:)
      result.fetch("token")
    end

    def create_order(amount, summary, fulfillment_url)
      url = "#{@backend_url}/private/orders"
      payload = {
        order: {
          amount: amount,
          summary: summary,
          fulfillment_url: fulfillment_url
        },
        create_token: false
      }
      request(url, payload:)
    end

    def order_status_url(order_id)
      "#{@backend_url}/orders/#{order_id}"
    end

    def fetch_order(order_id)
      url = "#{@backend_url}/private/orders/#{order_id}"
      request(url)
    end

    def refund_order(order_id, refund:, reason:)
      url = "#{@backend_url}/private/orders/#{order_id}/refund"
      payload = {refund:, reason:}
      request(url, payload:)
    end

    private

    def auth_token
      "secret-token:#{@password}"
    end

    def get(url, token = auth_token)
      headers = {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "User-Agent" => "Taler Ruby"
      }
      response = Net::HTTP.get(URI(url), headers)
      JSON.parse(response)
    end

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
