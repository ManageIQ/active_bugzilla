module ActiveBugzilla
  class Service < ServiceBase
    def xmlrpc_service
      @xmlrpc_service ||= ServiceViaXmlrpc.new(bugzilla_uri, username, password)
    end

    def python_service
      @python_service ||= ServiceViaPython.new(bugzilla_uri, username, password)
    end

    # Query for existing bugs
    #
    # Example:
    #   # Query for all NEW bugs, and return the output in a specific format.
    #   puts bz.query(
    #     :bug_status   => "NEW",
    #     :outputformat => "BZ_ID: %{id} STATUS: %{bug_status} SUMMARY: %{summary}"
    #   )
    #   # BZ_ID: 1234 STATUS: NEW SUMMARY: Something went wrong.
    #   # BZ_ID: 1235 STATUS: NEW SUMMARY: Another thing went wrong.
    #
    # @param options [Hash] Query options. Some possible values are:
    #   * <tt>:product</tt> - A specific product to limit the query against
    #   * <tt>:flag</tt> - Comma separated list of flags
    #   * <tt>:bug_status</tt> - Comma separated list of bug statuses, such as NEW,
    #     ASSIGNED, etc.
    #   * <tt>:outputformat</tt> - A string that will be used to format each line
    #     of output, with <tt>%{}</tt> as the interpolater.
    # @return [String] The command output
    def query(options)
      python_service.query(options)
    end

    # Modify an existing bug or set of bugs
    #
    # Examples:
    #   # Set the status of multiple bugs to RELEASE_PENDING
    #   bz.modify([948970, 948971], :status => "RELEASE_PENDING")
    #
    #   # Add a comment
    #   bz.modify("948972", :comment => "whatevs")
    #
    #   # Set the status to POST and add a comment
    #   bz.modify(948970, :status => "POST", :comment => "Fixed in shabla")
    #
    # @param bug_ids [String, Integer, Array<String>, Array<Integer>] The bug id
    #   or ids to process.
    # @param options [Hash] The properties to change.  Some properties include
    #   * <tt>:status</tt> - The bug status, such as NEW, ASSIGNED, etc.
    #   * <tt>:comment</tt> - Add a comment
    # @return [String] The command output
    def modify(bug_ids, options)
      python_service.modify(bug_ids, options)
    end

    # Clone of an existing bug
    #
    # Example:
    #   # Perform a clone of an existing bug, and return the new bug ID.
    #   bz.clone(948970)
    #
    # @param bug_id [String, Fixnum] A single bug id to process.
    # @param overrides [Hash] The properties to change from the source bug. Some properties include
    #   * <tt>:target_release</tt> - The target release for the new cloned bug.
    #   * <tt>:assigned_to</tt> - The person to assign the new cloned bug to.
    # @return [Fixnum] The bug id to the new, cloned, bug.
    def clone(bug_id, overrides={})
      xmlrpc_service.clone(bug_id, overrides)
    end

    # XMLRPC Bug Query of an existing bug
    #
    # Example:
    #   # Perform an xmlrpc query for a single bug.
    #   bz.get(948970)
    #
    # @param bug_id [Array, String, Fixnum] One or more bug ids to process.
    # @return [Array] Array of matching bug hashes.
    def get(bug_ids, include_fields = DEFAULT_FIELDS_TO_INCLUDE)
      xmlrpc_service.get(bug_ids, include_fields)
    end

    def search(options = {})
      xmlrpc_service.search(options)
    end
  end
end
