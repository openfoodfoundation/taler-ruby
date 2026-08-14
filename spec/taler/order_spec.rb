# frozen_string_literal: true

RSpec.describe Taler::Order do
  subject(:order) { Taler::Order.new(backend_url:, password:) }

  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }
  let(:password) { "sandbox" }

  it "is created, paid and refunded", :vcr do
    order.create(
      amount: "KUDOS:4",
      summary: "Order total",
      fulfillment_message: "Thank you for testing the payment."
    )
    expect(order.to_s)
      .to match %r[#<Taler::Order https://backend.demo.taler.net/instances/sandbox/orders/[0-9A-Z.-]+ {}>]

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

  it "can authenticate with an access token instead of a password" do
    order = Taler::Order.new(backend_url:, access_token: "secret-token:abc")
    request = stub_request(:post, "#{backend_url}/private/orders")
      .with(headers: {"Authorization" => "Bearer secret-token:abc"})
      .to_return(body: {order_id: "one"}.to_json)

    expect(order.create(amount: "KUDOS:4", summary: "Order total")).to eq "one"
    expect(request).to have_been_requested
  end

  it "requires a password or an access token" do
    expect { Taler::Order.new(backend_url:) }
      .to raise_error(ArgumentError, /password or an access_token/)
  end
end
