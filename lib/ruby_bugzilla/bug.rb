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
        raw_data[attribute_name]
      else
        super
      end
    end

    def comments
      @comments ||= begin
        raw_data['comments'].collect { |hash| BugComment.new(hash) }
      end
    end

    def attribute_names
      @attribute_names ||= raw_data.keys.sort
    end

    private

    def raw_data
      @raw_data ||= service.xmlrpc_bug_query(@id)
    end
  end
end
