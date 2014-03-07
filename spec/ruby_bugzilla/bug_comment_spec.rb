require 'spec_helper'

describe RubyBugzilla::BugComment do
  before(:each) do
    @author        = 'author@example.com'
    @bug_id        = 12345
    @count         = 0
    @id            = 42
    @text          = "This is a comment"
    @is_private    = true

    @bug_comment = described_class.new(
                     'author'     => @author,
                     'bug_id'     => @bug_id,
                     'count'      => @count,
                     'id'         => @id,
                     'text'       => @text,
                     'is_private' => @is_private)
  end

  it "#private?" do
    @bug_comment.private?.should == @is_private
  end

  it "#created_by" do
    @bug_comment.created_by.should == @author
  end

  it "#bug_id" do
    @bug_comment.bug_id.should == @bug_id
  end

  it "#id" do
    @bug_comment.id.should == @id
  end

  it "#text" do
    @bug_comment.text.should == @text
  end

end