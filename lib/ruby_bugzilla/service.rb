module RubyBugzilla
  class Service < ServiceBase
    def xmlrpc_service
      @xmlrpc_service ||= ServiceViaXmlrpc.new(bugzilla_uri, username, password)
    end

    def python_service
      @python_service ||= ServiceViaPython.new(bugzilla_uri, username, password)
    end

    def query(options)
      python_service.query(options)
    end

    def modify(bug_ids, options)
      python_service.modify(bug_ids, options)
    end

    def clone(bug_id, overrides={})
      xmlrpc_service.clone(bug_id, overrides)
    end

    def xmlrpc_bug_query(bug_ids, include_fields = DEFAULT_FIELDS_TO_INCLUDE)
      xmlrpc_service.query(bug_ids, include_fields)
    end
  end
end
