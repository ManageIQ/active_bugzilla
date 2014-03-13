module ActiveBugzilla
  class Comment < Base
    attr_reader :bug_id, :count, :created_by, :created_on, :creator_id, :id, :private, :text, :updated_on
    alias_method :private?, :private

    def initialize(attributes)
      @created_by = attributes['author']
      @bug_id     = attributes['bug_id']
      @count      = attributes['count']
      @creator_id = attributes['creator_id']
      @id         = attributes['id']
      @text       = attributes['text']

      @created_on = normalize_timestamp attributes['creation_time']
      @updated_on = normalize_timestamp attributes['time']
      @private    = attributes['is_private']
    end

    def self.instantiate_from_raw_data(data)
      data.sort_by(&:count).collect { |hash| new(hash) }
    end
  end
end
