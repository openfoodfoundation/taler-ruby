# GNU Taler payment API for Ruby

The Taler library let's you interact with a Taler merchant backend API to
take payments.

## Installation

```bash
gem install taler # or
bundle add taler
```

## Usage

```rb
backend_url = "https://backend.demo.taler.net/instances/sandbox"
backend_password = "sandbox"

order = Taler::Order.new(backend_url:, password:)
order.create(
  amount: "KUDOS:4",
  summary: "Order total",
  fulfillment_message: "Thank you!"
)

puts "Pay at: #{order.status_url}"

while order.fetch("order_status") == "unpaid"
  sleep 1
  order.reload
end

if order.fetch("order_status") == "paid"
  puts "Great. All paid."
else
  puts "Sorry, the order is #{order.fetch("order_status")}. Try again."
end
```

Read more in the official documentation:

- https://rubydoc.info/github/openfoodfoundation/taler-ruby.git

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake` to run the tests.
You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the
version, push git commits and the created tag, and push the `.gem` file
to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub
at https://github.com/openfoodfoundation/taler-ruby.
