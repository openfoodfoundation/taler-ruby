# frozen_string_literal: true

require "debug"

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

    if VCR.current_cassette.recording?
      puts "Pay at: #{order.status_url}"
      puts "Then continue by typing the letter c and enter."
      debugger
    end

    expect(order.fetch("order_status")).to eq "paid"

    order.refund(refund: "KUDOS:4", reason: "test")

    if VCR.current_cassette.recording?
      puts "Accept refund at: #{order.status_url}"
      puts "Then continue by typing the letter c and enter."
      debugger
    end

    expect { order.reload }.to change { order.fetch("refunded") }.to true
  end
end
