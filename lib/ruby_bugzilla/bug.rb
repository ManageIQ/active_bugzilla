module RubyBugzilla
  class Bug
    attr_reader :id, :service

    def initialize(id, service)
      @id      = id
      @service = service
    end

    def respond_to_missing?(meth, *args)
      attribute_names.include?(meth.to_s)
    end

    def method_missing(meth, *args, &block)
      attribute_name = meth.to_s
      if attribute_names.include?(attribute_name)
        attributes[attribute_name]
      else
        super
      end
    end

    def comments
      @comments ||= attributes['comments'].sort_by(&:count).collect { |hash| Comment.new(hash) }
    end

    def flags
      @flags ||= attributes['flags'].collect { |hash| Flag.new(hash.merge('bug_id' => @id)) }
    end

    def attribute_names
      @attribute_names ||= attributes.keys.sort
    end

    private

    def normalize_timestamp(timestamp)
      timestamp.respond_to?(:to_time) ? timestamp.to_time : nil
    end

    def raw_data
      @raw_data ||= service.xmlrpc_bug_query(@id).first
    end

    def normalize_attributes(hash)
      hash['created_on']   = normalize_timestamp(hash.delete('creation_time'))
      hash['updated_on']   = normalize_timestamp(hash.delete('last_change_time'))
      hash['created_by']   = hash.delete('creator')
      hash['duplicate_id'] = hash.delete('dupe_of')
      hash.delete_if { |k, v| v.nil? }
      hash
    end

    def attributes
      @attributes ||= normalize_attributes(raw_data)
    end
  end
end
