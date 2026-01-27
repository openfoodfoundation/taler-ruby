# frozen_string_literal: true

require "debug"

RSpec.describe Taler::Client do
  subject(:client) { Taler::Client.new(backend_url, backend_password) }

  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }
  let(:backend_password) { "sandbox" }

  it "retrieves a token", :vcr do
    token = client.request_token
    expect(token).to match(/^secret-token:/)
  end

  it "creates an order", :vcr do
    order = client.create_order("KUDOS:5.95", "Order total", "http://example.com")
    expect(order).to include("order_id" => /^20..\./)
  end

  it "fetches an order", :vcr do
    order = client.create_order("KUDOS:5.95", "Order total", "http://example.com")
    order_id = order.fetch("order_id")

    order = client.fetch_order(order_id)
    expect(order).to include("taler_pay_uri" => /^taler:\/\/pay\/backend\.de/)
    expect(order).to include("order_status_url" => /^https:\/\/backend\.demo/)
  end

  it "refunds an order", :vcr do
    order = client.create_order("KUDOS:2.00", "Tentative order", "http://example.com")
    order_id = order.fetch("order_id")

    order = client.fetch_order(order_id)

    if VCR.current_cassette.recording?
      puts "Pay at: #{order.fetch('order_status_url')}"
      puts "Then continue by typing the letter c and enter."
      debugger
    end

    result = client.refund_order(order_id, refund: "KUDOS:2.00", reason: "testing")
    expect(result).to include("taler_refund_uri" => /^taler:\/\/refund\/backend/)

    if VCR.current_cassette.recording?
      puts "Refund at: #{order.fetch('order_status_url')}"
      puts "Then continue by typing the letter c and enter."
      debugger
    end

    order = client.fetch_order(order_id)
    expect(order).to include("order_status" => "paid")
    expect(order).to include("refunded" => true)
  end
end
