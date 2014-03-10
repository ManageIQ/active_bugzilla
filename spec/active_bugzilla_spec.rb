require 'spec_helper'

describe ActiveBugzilla do
  it "::VERSION" do
    described_class::VERSION.should be_kind_of(String)
  end
end
