# frozen_string_literal: true

RSpec.describe Taler do
  it "has a version number" do
    expect(Taler::VERSION).not_to be nil
  end
end
