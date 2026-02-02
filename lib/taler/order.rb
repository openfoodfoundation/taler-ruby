# frozen_string_literal: true

module Taler
  # Order representation with convenient access to the merchant API.
  class Order
    # Connect an Order to the Taler merchant backend.
    #
    # @param backend_url [String] e.g. `"https://backend.demo.taler.net/instances/sandbox"`
    # @param password [String] e.g. `"sandbox"`
    # @param id [String] The order id of an existing order.
    # @example Connect to the official demo backend
    #   Taler::Order.new(
    #     backend_url: "https://backend.demo.taler.net/instances/sandbox",
    #     password: "sandbox"
    #   )
    def initialize(backend_url:, password:, id: nil)
      @client = Client.new(backend_url, password)
      @id = id
    end

    # Create a new order record ready to take a payment.
    #
    # @return [String] The id of the new order.
    def create(amount:, summary:, fulfillment_url: nil, fulfillment_message: nil)
      response = @client.create_order(
        amount:, summary:, fulfillment_url:, fulfillment_message:
      )
      @id = response.fetch("order_id")
    end

    # The page where the customer can pay or accept a refund,
    # depending on the state of the order.
    #
    # The merchant backend opens the Taler plugin or app if it can.
    # Otherwise it shows a QR code to scan in the app and provides
    # installation instructions.
    def status_url
      @client.order_status_url(@id)
    end

    # Access order status fields.
    #
    # It queries the backend if it hasn't done that already.
    # Call {#reload} beforehand to get the latest status from the backend.
    #
    # @param key [String] A field in the order status response of the backend,
    #   e.g. `order_status`.
    # @return [String,true,false] The value of the field.
    #   Any simple type supported by JSON.
    # @example
    #   fetch("order_status") #=> "unpaid"
    def fetch(key)
      reload unless @status
      @status.fetch(key)
    end

    # Query the latest order information from the backend.
    #
    # If you called {#fetch} in the past and are expecting updates from
    # user interaction, you want to call this.
    def reload
      @status = @client.fetch_order(@id)
    end

    # Issue a refund request for this order.
    #
    # @param refund [String] The amount with currency.
    # @param reason [String] Why are you refunding?
    #
    # @return [Hash] Response from the merchant backend.
    def refund(refund:, reason:)
      @client.refund_order(@id, refund:, reason:)
    end
  end
end
