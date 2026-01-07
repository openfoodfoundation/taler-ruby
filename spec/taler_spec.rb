# frozen_string_literal: true

RSpec.describe Taler do
  let(:backend_url) { "https://backend.demo.taler.net/instances/sandbox" }
  let(:backend_password) { "sandbox" }

  it "has a version number" do
    expect(Taler::VERSION).not_to be nil
  end

  it "retrieves a token", :vcr do
    token = Taler.request_token(backend_url, backend_password)
    expect(token).to match(/^secret-token:/)
  end

  it "creates an order", :vcr do
    order = Taler.create_order(backend_url, backend_password, "KUDOS:5.95", "Order total", "http://example.com")
    expect(order).to include("order_id" => /^20..\./)
  end
end
