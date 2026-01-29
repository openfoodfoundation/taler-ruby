# frozen_string_literal: true

RSpec.describe Taler::Client do
  subject(:client) { Taler::Client.new(backend_url, backend_password) }

  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }
  let(:backend_password) { "sandbox" }
  let(:fulfillment_message) { "Thank you for testing." }

  it "retrieves a token", :vcr do
    token = client.request_token
    expect(token).to match(/^secret-token:/)
  end

  it "creates an order", :vcr do
    order = client.create_order(amount: "KUDOS:5.95", summary: "Order total", fulfillment_message:)
    expect(order).to include("order_id" => /^20..\./)
  end

  it "fetches an order", :vcr do
    order = client.create_order(amount: "KUDOS:5.95", summary: "Order total", fulfillment_message:)
    order_id = order.fetch("order_id")

    order = client.fetch_order(order_id)
    expect(order).to include("taler_pay_uri" => /^taler:\/\/pay\/backend\.de/)
    expect(order).to include("order_status_url" => /^https:\/\/backend\.demo/)
  end

  it "refunds an order", :vcr do
    order = client.create_order(amount: "KUDOS:2.00", summary: "Tentative", fulfillment_message:)
    order_id = order.fetch("order_id")

    order = client.fetch_order(order_id)

    prompt "Pay at: #{order.fetch("order_status_url")}"

    result = client.refund_order(order_id, refund: "KUDOS:2.00", reason: "testing")
    expect(result).to include("taler_refund_uri" => /^taler:\/\/refund\/backend/)

    prompt "Refund at: #{order.fetch("order_status_url")}"

    order = client.fetch_order(order_id)
    expect(order).to include("order_status" => "paid")
    expect(order).to include("refunded" => true)
  end
end
