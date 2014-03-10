require 'spec_helper'

describe ActiveBugzilla::Service do
  let(:bz) { described_class.new("http://uri.to/bugzilla", "calvin", "hobbes") }

  context "#new" do
    it 'normal case' do
      expect { bz }.to_not raise_error
    end

    it "when bugzilla_uri is invalid" do
      expect { described_class.new("lalala", "", "") }.to raise_error(URI::BadURIError)
    end

    it "when username and password are not set" do
      expect { described_class.new("http://uri.to/bugzilla", nil, nil) }.to raise_error(ArgumentError)
    end
  end
end
