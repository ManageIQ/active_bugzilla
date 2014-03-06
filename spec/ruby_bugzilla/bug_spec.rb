require 'spec_helper'

describe RubyBugzilla::Bug do
  context "#new" do
    before(:each) do
      @id      = 12345
      @service = double(:service)
      @bug     = described_class.new(@id, @service)
    end

    it "attribute_names" do
      keys = ['severity', 'priority']
      raw_data = {}
      keys.each { |k| raw_data[k] = 'foo'}
      @bug.stub(:raw_data).and_return(raw_data)
      @bug.attribute_names.should == keys.sort
    end

    it "severity" do
      severity = 'foo'
      raw_data = { 'severity' => severity }
      @bug.stub(:raw_data).and_return(raw_data)
      @bug.severity.should == severity
    end

    it "comments" do
      comments_hash = [{'id' => 1}]
      raw_data = { 'comments' => comments_hash }
      @bug.stub(:raw_data).and_return(raw_data)
      comments = @bug.comments
      comments.should be_kind_of(Array)
      comments.count.should == 1
      comments.first.should be_kind_of(RubyBugzilla::BugComment)
    end

  end
end