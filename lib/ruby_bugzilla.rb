require 'fileutils'
require 'linux_admin'
require 'tempfile'
require "xmlrpc/client"


class RubyBugzilla
  CLONE_FIELDS = [:assigned_to, :cc, :cf_devel_whiteboard, :cf_internal_whiteboard, :component,
    :groups, :keywords, :op_sys, :platform, :priority, :product, :qa_contact, :severity,
    :summary, :target_release, :url, :version, :whiteboard, :comments, :description,]
  CMD = `which bugzilla`.chomp
  COOKIES_FILE = File.expand_path('~/.bugzillacookies')

  def self.installed?
    File.exists?(CMD)
  end

  attr_accessor :bugzilla_uri, :username, :password, :last_command, :xmlrpc
  attr_reader   :bugzilla_request_uri, :bugzilla_request_hostname

  def bugzilla_uri=(value)
    @bugzilla_request_uri = URI.join(value, "xmlrpc.cgi").to_s
    @bugzilla_request_hostname = URI(value).hostname
    @bugzilla_uri = value
  end

  def initialize(bugzilla_uri, username, password)
    raise "python-bugzilla not installed" unless installed?
    raise ArgumentError, "username and password must be set" if username.nil? || password.nil?

    self.bugzilla_uri = bugzilla_uri
    self.username     = username
    self.password     = password
    self.xmlrpc       = ::XMLRPC::Client.new(bugzilla_request_hostname, '/xmlrpc.cgi', 443, nil,
      nil, username, password, true, 60)

    login
  end

  def inspect
    super.gsub(/@password=\".+?\", /, "")
  end

  def installed?
    self.class.installed?
  end

  def clear_login!
    cookies_file_entry = "HttpOnly_.#{bugzilla_request_hostname}"

    if File.exists?(COOKIES_FILE)
      Tempfile.open('ruby_bugzilla') do |out_file|
        File.read(COOKIES_FILE).each_line do |line|
          out_file.puts(line) unless line.include? cookies_file_entry
        end
        out_file.close()
        FileUtils.mv(out_file.path, COOKIES_FILE)
      end
    end
  end

  def login
    params = {}
    params["--debug"] = nil
    params["login"]   = [username, password]

    begin
      execute_shell(params)
    rescue
      clear_login! # A failed login attempt could result in a corrupt COOKIES_FILE
      raise
    end
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
    raise ArgumentError, "options must be specified" if options.empty?

    params = {}
    params["query"] = nil
    set_params_options(params, options)

    execute_shell(params)
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
    bug_ids = Array(bug_ids)
    raise ArgumentError, "bug_ids and options must be specified" if bug_ids.empty? || options.empty?
    raise ArgumentError, "bug_ids must be numeric" unless bug_ids.all? {|id| id.to_s =~ /^\d+$/ }

    params = {}
    params["modify"] = bug_ids
    set_params_options(params, options)

    execute_shell(params)
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
    raise ArgumentError, "bug_id must be numeric" unless bug_id.to_s =~ /^\d+$/ 

    existing_bz = xmlrpc_bug_query(bug_id)

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

    execute_xmlrpc('create', params)[:id.to_s]
  end

  # XMLRPC Bug Query of an existing bug
  #
  # Example:
  #   # Perform an xmlrpc query for a single bug.
  #   bz.xmlrpc_bug_query(948970)
  #
  # @param bug_id [String, Fixnum] A single bug id to process.
  # @return [Fixnum] The bug id to the new, cloned, bug.
  def xmlrpc_bug_query(bug_id)
    raise ArgumentError, "bug_id must be numeric" unless bug_id.to_s =~ /^\d+$/ 

    params = {}
    params[:Bugzilla_login]    = username
    params[:Bugzilla_password] = password
    params[:ids]               = bug_id
    params[:include_fields]    = CLONE_FIELDS

    execute_xmlrpc('get', params)['bugs'].last
  end

  private
  def assemble_clone_description(existing_bz)
    clone_description = " +++ This bug was initially created as a clone of Bug ##{existing_bz[:id.to_s]} +++ \n"
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

  def set_params_options(params, options)
    options.each do |key,value|
      params["--#{key}="] = value
    end
  end

  # Execute the command using LinuxAdmin to execute python-bugzilla shell commands.
  def execute_shell(params)
    params = {"--bugzilla=" => bugzilla_request_uri}.merge(params)

    self.last_command = shell_command_string(CMD, params, password)
    LinuxAdmin.run!(CMD, :params => params).output
  end

  # Bypass python-bugzilla and use the xmlrpc API directly.
  def execute_xmlrpc(action, params)
    cmd = "Bug.#{action}"

    self.last_command = xmlrpc_command_string(cmd, params)
    xmlrpc.call(cmd, params)
  end

  # Build a printable representation of the python-bugzilla command executed.
  def shell_command_string(cmd, params = {}, password=nil)
    scrubbed_str = str = ""
    str << cmd
    params.each do |param, value|
      if value.kind_of?(Array)
        str << " #{param} \"#{value.join(" ")}\" "
      else
        if value.to_s.length == 0
          str << " #{param} "
        else
          str << " #{param}\"#{value}\" "
        end
      end
    end
    scrubbed_str = str.sub(password, "********") unless password.nil?
    scrubbed_str
  end

  # Build a printable representation of the xmlrcp command executed.
  def xmlrpc_command_string(cmd, params = {})
    clean_params = Hash[params]
    clean_params[:Bugzilla_password] = "********"
    "xmlrpc.call(#{cmd}, #{clean_params})"
  end

end
