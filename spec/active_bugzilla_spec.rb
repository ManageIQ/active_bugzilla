require 'spec_helper'

describe ActiveBugzilla do
  it "::VERSION" do
    expect(described_class::VERSION).to be_kind_of(String)
  end
end
