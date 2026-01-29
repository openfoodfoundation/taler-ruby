# frozen_string_literal: true

require "taler"
require "webmock/rspec"
require "vcr"

module PromptHelper
  def prompt(message)
    return unless VCR.current_cassette.recording?

    puts message
    puts "Then continue by typing the letter c and enter."
    debugger
  end
end

WebMock.enable!
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Change recording mode during development:
  #
  #   VCR_RECORD=new_episodes rspec spec/example_spec.rb
  #   VCR_RECORD=all          rspec spec/example_spec.rb
  #
  if ENV.fetch("VCR_RECORD", nil)
    config.default_cassette_options = {record: ENV.fetch("VCR_RECORD").to_sym}
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include PromptHelper
end
