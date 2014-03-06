module RubyBugzilla
  class BugComment
    attr_reader :author, :bug_id, :count, :creation_time, :creator_id, :id, :text, :time

    def initialize(attributes)
      @author        = attributes['author']
      @bug_id        = attributes['bug_id']
      @count         = attributes['count']
      @creation_time = attributes['creation_time']
      @creator_id    = attributes['creator_id']
      @id            = attributes['id']
      @text          = attributes['text']
      @time          = attributes['time']

      @private       = attributes['is_private']
    end

    def private?
      @private
    end
  end
end
