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

## Authentication

By default, all requests authenticate with the instance password. That is
deprecated since merchant API v19 but it is the only method that works
unattended on every endpoint.

Alternatively, you can pass an access token obtained elsewhere, for example
from the merchant backoffice, and keep the password to yourself:

```rb
order = Taler::Order.new(backend_url:, access_token: "secret-token:...")
```

`Taler::Client#request_token` can obtain such a token, optionally limited in
scope and duration:

```rb
client = Taler::Client.new(backend_url, password)
client.request_token(scope: "order-mgmt:refreshable")
```

Note that the backend may require two-factor authentication for that endpoint.
It then answers with a list of challenges to solve and this gem raises
`Taler::ChallengeRequired`. Solving challenges needs a person to enter a TAN
and isn't supported yet. Since the order endpoints are never challenged,
password authentication keeps working on such a backend.

## Errors

All requests raise `Taler::RequestError` when the backend responds with an
unexpected status code. The error carries the `status` and the raw `body` of
the response.

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
