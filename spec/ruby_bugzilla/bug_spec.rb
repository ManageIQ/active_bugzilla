require 'spec_helper'

describe RubyBugzilla::Bug do
  context "#new" do
    before(:each) do
      @id      = 123
      @service = double(:service)
      @bug     = described_class.new(@id, @service)
    end

    it "attribute_names" do
      keys = %w(severity priority)
      raw_data = {}
      keys.each { |k| raw_data[k] = 'foo' }
      @bug.stub(:raw_data).and_return(raw_data)
      expect(@bug.attribute_names).to eq(keys.sort)
    end

    it "severity" do
      severity = 'foo'
      raw_data = {'severity' => severity}
      @bug.stub(:raw_data).and_return(raw_data)
      expect(@bug.severity).to eq(severity)
    end

    it "comments" do
      comments_hash = [{'id' => 1}]
      raw_data = {'comments' => comments_hash}
      @bug.stub(:raw_data).and_return(raw_data)
      comments = @bug.comments
      expect(comments).to be_kind_of(Array)
      expect(comments.count).to eq(1)
      expect(comments.first).to be_kind_of(RubyBugzilla::BugComment)
    end

  end
end
