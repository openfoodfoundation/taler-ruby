# frozen_string_literal: true

RSpec.describe Taler::Order do
  subject(:order) { Taler::Order.new(backend_url:, password:) }

  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }
  let(:password) { "sandbox" }

  it "is created, paid and refunded", :vcr do
    order.create(
      amount: "KUDOS:4",
      summary: "Order total",
      fulfillment_url: "http://example.com"
    )

    prompt "Pay at: #{order.status_url}"

    expect(order.fetch("order_status")).to eq "paid"

    order.refund(refund: "KUDOS:4", reason: "test")

    prompt "Accept refund at: #{order.status_url}"

    expect { order.reload }.to change { order.fetch("refunded") }.to true
  end
end
