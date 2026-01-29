# frozen_string_literal: true

module Taler
  # Order representation with convenient access to the merchant API.
  class Order
    def initialize(backend_url:, password:, id: nil)
      @client = Client.new(backend_url, password)
      @id = id
    end

    def create(amount:, summary:, fulfillment_url:, fulfillment_message: nil)
      response = @client.create_order(amount, summary, fulfillment_url)
      @id = response.fetch("order_id")
    end

    def status_url
      @client.order_status_url(@id)
    end

    def fetch(key)
      reload unless @status
      @status.fetch(key)
    end

    def reload
      @status = @client.fetch_order(@id)
    end

    def refund(refund:, reason:)
      @client.refund_order(@id, refund:, reason:)
    end
  end
end
