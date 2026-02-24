# frozen_string_literal: true

RSpec.describe Taler do
  it "has a version number" do
    expect(Taler::VERSION).not_to be nil
  end

  it "has an up-to-date RBS file" do
    expect { `sord sig/taler.rbs` }.not_to change { File.read("sig/taler.rbs") }
  end
end
