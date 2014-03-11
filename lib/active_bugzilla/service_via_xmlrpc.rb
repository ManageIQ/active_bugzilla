require 'xmlrpc/client'
require 'active_bugzilla/service_via_xmlrpc/clone'

module ActiveBugzilla
  class ServiceViaXmlrpc < ServiceBase
    DEFAULT_CGI_PATH   = '/xmlrpc.cgi'
    DEFAULT_PORT       = 443
    DEFAULT_PROXY_HOST = nil
    DEFAULT_PROXY_PORT = nil
    DEFAULT_USE_SSL    = true
    DEFAULT_TIMEOUT    = 120

    def xmlrpc_client
      @xmlrpc_client ||= ::XMLRPC::Client.new(
                            bugzilla_request_hostname,
                            DEFAULT_CGI_PATH,
                            DEFAULT_PORT,
                            DEFAULT_PROXY_HOST,
                            DEFAULT_PROXY_PORT,
                            username,
                            password,
                            DEFAULT_USE_SSL,
                            timeout || DEFAULT_TIMEOUT)
    end

    # http://www.bugzilla.org/docs/4.2/en/html/api/Bugzilla/WebService/Bug.html#fields
    def fields(params = {})
      execute('fields', params)['fields']
    end

    # http://www.bugzilla.org/docs/4.2/en/html/api/Bugzilla/WebService/Bug.html#get
    def get(bug_ids, include_fields = DEFAULT_FIELDS_TO_INCLUDE)
      bug_ids = Array(bug_ids)
      raise ArgumentError, "bug_ids must be all Numeric" unless bug_ids.all? { |id| id.to_s =~ /^\d+$/ }

      params                  = {}
      params[:ids]            = bug_ids
      params[:include_fields] = include_fields

      results = execute('get', params)['bugs']
      return [] if results.nil?
      results
    end

    # http://www.bugzilla.org/docs/4.2/en/html/api/Bugzilla/WebService/Bug.html#search
    def search(params = {})
      params[:include_fields]   ||= DEFAULT_FIELDS_TO_INCLUDE
      params[:ids]              &&= Array(params[:id])
      params[:creation_time]    &&= to_xmlrpc_timestamp(params[:creation_time])
      params[:last_change_time] &&= to_xmlrpc_timestamp(params[:last_change_time])
      params[:product]          ||= product

      results = execute('search', params)['bugs']
      return [] if results.nil?
      results
    end

    # http://www.bugzilla.org/docs/4.2/en/html/api/Bugzilla/WebService/Bug.html#update
    def update(ids, params = {})
    end

    # http://www.bugzilla.org/docs/4.2/en/html/api/Bugzilla/WebService/Bug.html#create
    def create(params)
      execute('create', params)
    end

    # Bypass python-bugzilla and use the xmlrpc API directly.
    def execute(action, params)
      cmd = "Bug.#{action}"

      params[:Bugzilla_login]    ||= username
      params[:Bugzilla_password] ||= password

      self.last_command = command_string(cmd, params)
      xmlrpc_client.call(cmd, params)
    end

    private

    def to_xmlrpc_timestamp(ts)
      return ts if ts.kind_of?(XMLRPC::DateTime)
      return ts unless ts.respond_to?(:to_time)
      ts = ts.to_time
      XMLRPC::DateTime.new(ts.year, ts.month, ts.day, ts.hour, ts.min, ts.sec)
    end

    # Build a printable representation of the xmlrcp command executed.
    def command_string(cmd, params)
      clean_params = Hash[params]
      clean_params[:Bugzilla_password] = "********"
      "xmlrpc_client.call(#{cmd}, #{clean_params})"
    end
  end
end
