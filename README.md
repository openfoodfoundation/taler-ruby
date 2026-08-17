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
require "taler"

backend_url = "https://backend.demo.taler.net/instances/sandbox"
password = "sandbox"

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

- https://rubydoc.info/gems/taler

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake` to run the tests.
You can also run `bin/console` for an interactive prompt.

## Release

- Update the version number in `lib/taler/version.rb`.
- Update the `CHANGELOG.md` file.
- Run `bundle update`.
- Commit.
- Run `bundle exec rake release` to build, tag and push the gem.

## Contributing

Bug reports and pull requests are welcome on GitHub
at https://github.com/openfoodfoundation/taler-ruby.
