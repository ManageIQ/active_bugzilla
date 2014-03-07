module RubyBugzilla
  class Flag < Base
    attr_reader :bug_id, :created_on, :id, :name, :setter, :status, :type_id, :updated_on

    def initialize(attributes)
      @id         = attributes['id']
      @bug_id     = attributes['bug_id']
      @type_id    = attributes['type_id']
      @created_on = normalize_timestamp(attributes['creation_date'])
      @updated_on = normalize_timestamp(attributes['modification_date'])
      @status     = attributes['status']
      @name       = attributes['name']
      @setter     = attributes['setter']
      @active     = attributes['is_active']
    end

    def active?
      @active
    end
  end
end
