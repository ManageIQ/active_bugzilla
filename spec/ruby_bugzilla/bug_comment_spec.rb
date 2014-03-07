require 'spec_helper'

describe RubyBugzilla::BugComment do
  before(:each) do
    @author        = 'author@example.com'
    @bug_id        = 123
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
    expect(@bug_comment.private?).to eq(@is_private)
  end

  it "#created_by" do
    expect(@bug_comment.created_by).to eq(@author)
  end

  it "#bug_id" do
    expect(@bug_comment.bug_id).to eq(@bug_id)
  end

  it "#id" do
    expect(@bug_comment.id).to eq(@id)
  end

  it "#text" do
    expect(@bug_comment.text).to eq(@text)
  end

end
