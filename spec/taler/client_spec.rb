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

  describe "error responses" do
    let(:orders_url) { "#{backend_url}/private/orders" }

    it "raises on any error with a Taler::Error" do
      stub_request(:post, orders_url).to_raise(EOFError)

      expect { client.create_order(amount: "KUDOS:1", summary: "Test") }
        .to raise_error(Taler::Error)
    end

    it "raises with the explanation of the backend when a request is rejected" do
      stub_request(:post, orders_url).to_return(
        status: 401,
        body: {code: 2015, hint: "The merchant refused the request due to lack of authorization."}.to_json
      )

      expect { client.create_order(amount: "KUDOS:1", summary: "Test") }.to raise_error(
        an_instance_of(Taler::RequestError).and(having_attributes(
          status: 401,
          body: include("code" => 2015),
          message: "The Taler backend responded with 401: " \
            "The merchant refused the request due to lack of authorization."
        ))
      )
    end

    it "raises when fetching an unknown order" do
      stub_request(:get, "#{orders_url}/unknown")
        .to_return(status: 404, body: {code: 2000, hint: "Order unknown"}.to_json)

      expect { client.fetch_order("unknown") }
        .to raise_error(Taler::RequestError, "The Taler backend responded with 404: Order unknown")
    end

    it "keeps a body that is not JSON as text" do
      stub_request(:post, orders_url).to_return(status: 502, body: "<html>Bad Gateway</html>")

      expect { client.create_order(amount: "KUDOS:1", summary: "Test") }.to raise_error(
        an_instance_of(Taler::RequestError).and(having_attributes(
          status: 502,
          body: "<html>Bad Gateway</html>",
          message: "The Taler backend responded with 502: <html>Bad Gateway</html>"
        ))
      )
    end

    it "treats a two-factor authentication challenge as an error" do
      stub_request(:post, "#{backend_url}/private/token").to_return(
        status: 202,
        body: {challenges: [{tan_channel: "email", challenge_id: "1"}], combi_and: false}.to_json
      )

      expect { client.request_token }.to raise_error(
        an_instance_of(Taler::RequestError).and(having_attributes(
          status: 202,
          body: include("challenges")
        ))
      )
    end
  end
end
