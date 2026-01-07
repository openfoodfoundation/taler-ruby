# frozen_string_literal: true

require "json"
require "net/http"
require_relative "taler/version"

module Taler
  class Error < StandardError; end

  def self.request_token(backend_url, password)
    url = "#{backend_url}/private/token"
    token = "secret-token:#{password}"
    payload = {scope: "write"}
    result = post(url, token, payload)
    result.fetch("token")
  end

  def self.create_order(backend_url, password, amount, summary, fulfillment_url)
    url = "#{backend_url}/private/orders"
    token = request_token(backend_url, password)
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

  def self.post(url, token, payload)
    headers = {
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "User-Agent" => "Taler Ruby"
    }
    data = JSON.dump(payload)
    response = Net::HTTP.post(URI(url), data, headers)
    JSON.parse(response.body)
  end
end
