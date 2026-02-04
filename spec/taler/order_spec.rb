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

    # The spaces are only included in Ruby >= 3.4.
    # We can remove the question marks after dropping support for Ruby 3.3.
    # Ruby 3.3 support officially ends in April 2027.
    expect(order.to_s).to match(/{"order_status" ?=> ?"paid", ?"refunded" ?=> ?false}>/)

    order.refund(refund: "KUDOS:4", reason: "test")

    prompt "Accept refund at: #{order.status_url}"

    expect { order.reload }.to change { order.fetch("refunded") }.to true

    expect(order.inspect).to match(/"order_status" ?=> ?"paid"/)
    expect(order.inspect).to match(/"wired" ?=> ?true/)
    expect(order.inspect).to match(/"refunded" ?=> ?true/)
    expect(order.inspect).to match(/"refund_amount" ?=> ?"KUDOS:4"/)
  end
end
