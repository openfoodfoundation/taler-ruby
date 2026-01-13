# frozen_string_literal: true

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
end
