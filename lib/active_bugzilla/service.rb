require 'xmlrpc/client'

module ActiveBugzilla
  class Service
    CLONE_FIELDS = [
      :assigned_to,
      :cc,
      :cf_devel_whiteboard,
      :cf_internal_whiteboard,
      :comments,
      :component,
      :description,
      :groups,
      :keywords,
      :op_sys,
      :platform,
      :priority,
      :product,
      :qa_contact,
      :severity,
      :summary,
      :target_release,
      :url,
      :version,
      :whiteboard
    ]

    attr_accessor :bugzilla_uri, :username, :password, :last_command
    attr_reader   :bugzilla_request_uri, :bugzilla_request_hostname

    def self.timeout=(value)
      @@timeout = value
    end

    def self.timeout
      defined?(@@timeout) && @@timeout
    end

    def timeout
      self.class.timeout
    end

    def self.product=(value)
      @@product = value
    end

    def self.product
      defined?(@@product) && @@product
    end

    def product
      self.class.product
    end

    def bugzilla_uri=(value)
      @bugzilla_request_uri      = URI.join(value, "xmlrpc.cgi").to_s
      @bugzilla_request_hostname = URI(value).hostname
      @bugzilla_uri              = value
    end

    def https?
      URI.parse(bugzilla_uri).scheme == 'https'
    end

    def initialize(bugzilla_uri, username, password, options = {})
      raise ArgumentError, "username and password must be set" if username.nil? || password.nil?

      self.bugzilla_uri = bugzilla_uri
      self.username     = username
      self.password     = password

      @options = DEFAULT_OPTIONS.merge(options)
      @options[:use_ssl] ||= self.https?
      @options[:port] ||= (@options[:use_ssl] ? 443 : 80)
    end

    def inspect
      super.gsub(/@password=\".+?\", /, "")
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#comments
    def comments(params = {})
      execute('Bug.comments', params)
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#add_comment
    def add_comment(bug_id, comment, params = {})
      params[:id]      = bug_id
      params[:comment] = comment
      execute('Bug.add_comment', params)["id"]
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#fields
    def fields(params = {})
      execute('Bug.fields', params)['fields']
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#get
    # XMLRPC Bug Query of an existing bug
    #
    # Example:
    #   # Perform an xmlrpc query for a single bug.
    #   bz.get(948970)
    #
    # @param bug_id [Array, String, Fixnum] One or more bug ids to process.
    # @return [Array] Array of matching bug hashes.
    def get(bug_ids, params = {})
      bug_ids = Array(bug_ids)
      raise ArgumentError, "bug_ids must be all Numeric" unless bug_ids.all? { |id| id.to_s =~ /^\d+$/ }

      params[:ids] = bug_ids

      results = execute('Bug.get', params)['bugs']
      return [] if results.nil?
      results
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#search
    def search(params = {})
      params[:creation_time]    &&= to_xmlrpc_timestamp(params[:creation_time])
      params[:last_change_time] &&= to_xmlrpc_timestamp(params[:last_change_time])
      params[:product]          ||= product if product

      results = execute('Bug.search', params)['bugs']
      return [] if results.nil?
      results
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#update
    def update(ids, params = {})
      params[:ids] = Array(ids)
      execute('Bug.update', params)['bugs']
    end

    # http://www.bugzilla.org/docs/4.4/en/html/api/Bugzilla/WebService/Bug.html#create
    def create(params)
      execute('Bug.create', params)
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
    def clone(bug_id, overrides = {})
      raise ArgumentError, "bug_id must be numeric" unless bug_id.to_s =~ /^\d+$/

      existing_bz = get(bug_id, :include_fields => CLONE_FIELDS).first

      clone_description, clone_comment_is_private = assemble_clone_description(existing_bz)

      params = {}
      CLONE_FIELDS.each do |field|
        next if field == :comments
        params[field] = existing_bz[field.to_s]
      end

      # Apply overrides
      overrides.each do |param, value|
        params[param] = value
      end

      # Apply base clone fields
      params[:cf_clone_of]        = bug_id
      params[:description]        = clone_description
      params[:comment_is_private] = clone_comment_is_private

      create(params)[:id.to_s]
    end

    def execute(command, params)
      params[:Bugzilla_login]    ||= username
      params[:Bugzilla_password] ||= password

      self.last_command = command_string(command, params)
      xmlrpc_client.call(command, params)
    end
    alias_method :call, :execute

    private

    DEFAULT_OPTIONS = {
      :cgi_path => '/xmlrpc.cgi',
      :timeout  => 120
    }

    def xmlrpc_client
      @xmlrpc_client ||= ::XMLRPC::Client.new(
                            bugzilla_request_hostname,
                            @options[:cgi_path],
                            @options[:port],
                            @options[:proxy_host],
                            @options[:proxy_port],
                            username,
                            password,
                            @options[:use_ssl],
                            timeout || @options[:timeout])
    end

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

    def assemble_clone_description(existing_bz)
      clone_description = " +++ This bug was initially created as a clone of Bug ##{existing_bz[:id]} +++ \n"
      clone_description << existing_bz[:description.to_s]

      clone_comment_is_private = false
      existing_bz[:comments.to_s].each do |comment|
        clone_description << "\n\n"
        clone_description << "*" * 70
        clone_description << "\nFollowing comment by %s on %s\n\n" %
          [comment['author'], comment['creation_time'].to_time]
        clone_description << "\n\n"
        clone_description << comment['text']
        clone_comment_is_private = true if comment['is_private']
      end

      [clone_description, clone_comment_is_private]
    end
  end
end
