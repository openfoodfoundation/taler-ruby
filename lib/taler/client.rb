# frozen_string_literal: true

require 'json'
require 'net/http'

module Taler
  class Client
    def initialize(backend_url, password)
      @backend_url = backend_url
      @password = password
    end

    def request_token
      url = "#{@backend_url}/private/token"
      token = "secret-token:#{@password}"
      payload = { scope: 'write' }
      result = post(url, token, payload)
      result.fetch('token')
    end

    def create_order(amount, summary, fulfillment_url)
      url = "#{@backend_url}/private/orders"
      token = request_token
      payload = {
        order: {
          amount: amount,
          summary: summary,
          fulfillment_url: fulfillment_url
        },
        create_token: false
      }
      post(url, token, payload)
    end

    def fetch_order(order_id)
      url = "#{@backend_url}/private/orders/#{order_id}"
      token = request_token
      get(url, token)
    end

    private

    def get(url, token)
      headers = {
        'Authorization' => "Bearer #{token}",
        'Accept' => 'application/json',
        'User-Agent' => 'Taler Ruby'
      }
      response = Net::HTTP.get(URI(url), headers)
      JSON.parse(response)
    end

    def post(url, token, payload)
      headers = {
        'Authorization' => "Bearer #{token}",
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'User-Agent' => 'Taler Ruby'
      }
      data = JSON.dump(payload)
      response = Net::HTTP.post(URI(url), data, headers)
      JSON.parse(response.body)
    end
  end
end
