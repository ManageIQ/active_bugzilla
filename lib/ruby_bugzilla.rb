require 'linux_admin'

class RubyBugzilla
  CMD = `which bugzilla`.chomp
  COOKIES_FILE = File.expand_path('~/.bugzillacookies')

  def self.installed?
    File.exists?(CMD)
  end

  def self.logged_in?
    File.exists?(COOKIES_FILE)
  end

  def self.clear_login!
    File.delete(COOKIES_FILE) if File.exists?(COOKIES_FILE)
  end

  attr_accessor :username, :password, :bugzilla_uri, :last_command

  def initialize(username, password, options = {})
    raise "python-bugzilla not installed" unless self.class.installed?
    raise ArgumentError, "username and password must be set" if username.nil? || password.nil?

    self.username     = username
    self.password     = password
    self.bugzilla_uri = options[:bugzilla_uri] || "https://bugzilla.redhat.com"
  end

  def inspect
    super.gsub(/@password=\".+?\", /, "")
  end

  def login
    if self.class.logged_in?
      self.last_command = nil
      return "Already Logged In"
    end

    params = {}
    params["--debug"] = nil
    params["login"]   = [username, password]

    begin
      execute(params)
    rescue
      self.class.clear_login! # A failed login attempt could result in a corrupt COOKIES_FILE
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

    execute(params)
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

    execute(params)
  end

  private

  def bugzilla_request_uri
    URI.join(bugzilla_uri, "xmlrpc.cgi").to_s
  end

  def execute(params)
    params = {"--bugzilla=" => bugzilla_request_uri}.merge(params)

    self.last_command = string_command(CMD, params, password)
    LinuxAdmin.run!(CMD, :params => params).output
  end

  def set_params_options(params, options)
    options.each do |key,value|
      params["--#{key}="] = value
    end
  end

  def string_command(cmd, params = {}, password=nil)
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
end
