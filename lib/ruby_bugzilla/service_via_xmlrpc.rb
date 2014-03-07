require 'xmlrpc/client'
require 'ruby_bugzilla/service_via_xmlrpc/clone'

module RubyBugzilla
  class ServiceViaXmlrpc < ServiceBase
    def xmlrpc_client
      @xmlrpc_client ||= ::XMLRPC::Client.new(
                            bugzilla_request_hostname,
                            '/xmlrpc.cgi',
                            443,
                            nil,
                            nil,
                            username,
                            password,
                            true,
                            60)
    end

    # XMLRPC Bug Query of an existing bug
    #
    # Example:
    #   # Perform an xmlrpc query for a single bug.
    #   bz.xmlrpc_bug_query(948970)
    #
    # @param bug_id [Array, String, Fixnum] One or more bug ids to process.
    # @return [Array] Array of matching bug hashes.
    def query(bug_ids, include_fields = DEFAULT_FIELDS_TO_INCLUDE)
      bug_ids = Array(bug_ids)
      raise ArgumentError, "bug_ids must be all Numeric" unless bug_ids.all? { |id| id.to_s =~ /^\d+$/ }

      params = {}
      params[:Bugzilla_login]    = username
      params[:Bugzilla_password] = password
      params[:ids]               = bug_ids
      params[:include_fields]    = include_fields

      results = execute('get', params)['bugs']
      return [] if results.nil?
      results
    end

    # Bypass python-bugzilla and use the xmlrpc API directly.
    def execute(action, params)
      cmd = "Bug.#{action}"

      self.last_command = command_string(cmd, params)
      xmlrpc_client.call(cmd, params)
    end

    private

    # Build a printable representation of the xmlrcp command executed.
    def command_string(cmd, params)
      clean_params = Hash[params]
      clean_params[:Bugzilla_password] = "********"
      "xmlrpc_client.call(#{cmd}, #{clean_params})"
    end
  end
end
