# frozen_string_literal: true

require "json"
require "net/http"
require_relative "taler/version"

module Taler
  class Error < StandardError; end

  def self.request_token(backend_url, password)
    url = "#{backend_url}/private/token"
    headers = {
      "Authorization" => "Bearer secret-token:#{password}",
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "User-Agent" => "Taler Ruby"
    }
    data = JSON.dump(scope: "write")
    response = Net::HTTP.post(URI(url), data, headers)
    JSON.parse(response.body).fetch("token")
  end

  def self.create_order(backend_url, password, amount, summary, fulfillment_url)
    url = "#{backend_url}/private/orders"
    token = request_token(backend_url, password)
    headers = {
      "Authorization" => "Bearer #{token}",
      "Accept" => "application/json",
      "Content-Type" => "application/json",
      "User-Agent" => "Taler Ruby"
    }
    payload = {
      order: {
        amount: amount,
        summary: summary,
        fulfillment_url: fulfillment_url
      },
      create_token: false
    }
    data = JSON.dump(payload)
    response = Net::HTTP.post(URI(url), data, headers)
    JSON.parse(response.body)
  end
end
