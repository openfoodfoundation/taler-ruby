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
    expect(order.to_s)
      .to eq "#<Taler::Order https://backend.demo.taler.net/instances/sandbox/orders/2026.029-02M2JNJ2TGA2P {}>"

    prompt "Pay at: #{order.status_url}"

    expect(order.fetch("order_status")).to eq "paid"
    expect(order.to_s)
      .to eq "#<Taler::Order https://backend.demo.taler.net/instances/sandbox/orders/2026.029-02M2JNJ2TGA2P {\"order_status\" => \"paid\", \"refunded\" => false}>"

    order.refund(refund: "KUDOS:4", reason: "test")

    prompt "Accept refund at: #{order.status_url}"

    expect { order.reload }.to change { order.fetch("refunded") }.to true

    expect(order.inspect)
      .to eq '#<Taler::Order https://backend.demo.taler.net/instances/sandbox/orders/2026.029-02M2JNJ2TGA2P {"order_status" => "paid", "deposit_total" => "KUDOS:0", "wired" => true, "refunded" => true, "refund_pending" => false, "refund_amount" => "KUDOS:4"}>'
  end
end
