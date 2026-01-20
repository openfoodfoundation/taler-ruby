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
client = Taler::Client.new(backend_url, backend_password)

order = client.create_order("KUDOS:5.95", "Order total", "http://example.com")
order = client.fetch_order(order.fetch("order_id"))

puts "Pleas pay at: #{order['order_status_url']}"
```

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
