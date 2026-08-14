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

  describe "authentication" do
    let(:orders_url) { "#{backend_url}/private/orders" }

    it "requires a password or an access token" do
      expect { Taler::Client.new(backend_url) }
        .to raise_error(ArgumentError, /password or an access_token/)
    end

    it "authenticates with the instance password by default" do
      request = stub_request(:post, orders_url)
        .with(headers: {"Authorization" => "Bearer secret-token:sandbox"})
        .to_return(body: {order_id: "one"}.to_json)

      client.create_order(amount: "KUDOS:1", summary: "Order total")

      expect(request).to have_been_requested
    end

    it "doesn't request an access token" do
      token_request = stub_request(:post, "#{backend_url}/private/token")
      stub_request(:post, orders_url).to_return(body: {order_id: "one"}.to_json)

      client.create_order(amount: "KUDOS:1", summary: "Order total")

      expect(token_request).not_to have_been_requested
    end

    it "authenticates with a given access token" do
      client = Taler::Client.new(backend_url, access_token: "secret-token:abc")
      request = stub_request(:post, orders_url)
        .with(headers: {"Authorization" => "Bearer secret-token:abc"})
        .to_return(body: {order_id: "one"}.to_json)

      client.create_order(amount: "KUDOS:1", summary: "Order total")

      expect(request).to have_been_requested
    end

    it "prefers the access token of a token request over the deprecated one" do
      stub_request(:post, "#{backend_url}/private/token")
        .to_return(body: {token: "secret-token:old", access_token: "secret-token:new"}.to_json)

      expect(client.request_token).to eq "secret-token:new"
    end

    it "falls back to the deprecated token field" do
      stub_request(:post, "#{backend_url}/private/token")
        .to_return(body: {token: "secret-token:old"}.to_json)

      expect(client.request_token).to eq "secret-token:old"
    end
  end

  describe "error handling" do
    let(:order_url) { "#{backend_url}/private/orders/one" }

    it "raises an error when the backend rejects the request" do
      stub_request(:get, order_url).to_return(status: 401, body: "Unauthorized")

      expect { client.fetch_order("one") }.to raise_error(Taler::RequestError) { |error|
        expect(error.message).to include "401"
        expect(error.message).to include "Unauthorized"
        expect(error.status).to eq 401
        expect(error.body).to eq "Unauthorized"
      }
    end

    it "raises an error when the backend fails" do
      stub_request(:get, order_url).to_return(status: 500, body: "<html>Oops</html>")

      expect { client.fetch_order("one") }
        .to raise_error(Taler::RequestError, /500/)
    end

    it "truncates long error bodies" do
      stub_request(:get, order_url).to_return(status: 502, body: "x" * 900)

      expect { client.fetch_order("one") }.to raise_error(Taler::RequestError) { |error|
        expect(error.message).to end_with "..."
        expect(error.message.length).to be < 600
        expect(error.body.length).to eq 900
      }
    end

    it "raises a challenge error when the backend requires MFA" do
      challenge = {
        challenges: [
          {challenge_id: "one", tan_channel: "email", tan_info: "m...@example.com"},
          {challenge_id: "two", tan_channel: "sms", tan_info: "+61...789"}
        ],
        combi_and: false
      }
      stub_request(:post, "#{backend_url}/private/token")
        .to_return(status: 202, body: challenge.to_json)

      expect { client.request_token }.to raise_error(Taler::ChallengeRequired) { |error|
        expect(error.message).to include "multi-factor authentication via email, sms"
        expect(error.message).to include "instance password"
        expect(error.status).to eq 202
        expect(error.challenges.map { |c| c["challenge_id"] }).to eq %w[one two]
        expect(error.combi_and).to be false
      }
    end

    it "raises a challenge error even without a readable body" do
      stub_request(:post, "#{backend_url}/private/token")
        .to_return(status: 202, body: "<html>Accepted</html>")

      expect { client.request_token }.to raise_error(Taler::ChallengeRequired) { |error|
        expect(error.challenges).to eq []
        expect(error.combi_and).to be false
      }
    end

    it "raises a challenge error that can be rescued as a request error" do
      stub_request(:post, "#{backend_url}/private/token")
        .to_return(status: 202, body: "{}")

      expect { client.request_token }.to raise_error(Taler::RequestError)
    end
  end
end
