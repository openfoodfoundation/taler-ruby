# frozen_string_literal: true

RSpec.describe Taler do
  it "has a version number" do
    expect(Taler::VERSION).not_to be nil
  end

  it "has an up-to-date RBS file" do
    expect {
      # Since yard reads .rbs files, we have to remove it first.
      # https://github.com/AaronC81/sord/issues/193
      `rm sig/taler.rbs`
      `sord sig/taler.rbs`
    }.not_to change { File.read("sig/taler.rbs") }
  end
end
