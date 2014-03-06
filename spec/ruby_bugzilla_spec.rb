require 'spec_helper'

describe RubyBugzilla do
  it "::VERSION" do
    described_class::VERSION.should be_kind_of(String)
  end
end
