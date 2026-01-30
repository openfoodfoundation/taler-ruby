# frozen_string_literal: true

require_relative "lib/taler/version"

Gem::Specification.new do |spec|
  spec.name = "taler"
  spec.version = Taler::VERSION
  spec.authors = ["Maikel Linke"]
  spec.email = ["maikel@email.org.au"]
  spec.licenses = "LGPL-2.1-only"

  spec.summary = "GNU Taler payment API for Ruby"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://rubydoc.info/github/openfoodfoundation/taler-ruby.git"
  spec.required_ruby_version = ">= 3.4.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/openfoodfoundation/taler-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/openfoodfoundation/taler-ruby/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # Development:
  spec.add_development_dependency "irb"
  spec.add_development_dependency "rake"

  # Testing:
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"

  # Code quality:
  spec.add_development_dependency "standard"

  # Documentation:
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
