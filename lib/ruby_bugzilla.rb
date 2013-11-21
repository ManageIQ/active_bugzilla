require 'linux_admin'

class RubyBugzilla
  CMD = `which bugzilla`.chomp
  COOKIES_FILE = File.expand_path('~/.bugzillacookies')

  class << self
    attr_accessor :username, :password, :bugzilla_uri, :debug_login
  end

  def self.bugzilla_uri
    @bugzilla_uri ||= "https://bugzilla.redhat.com"
  end

  def self.bugzilla_request_uri
    URI.join(bugzilla_uri, "xmlrpc.cgi").to_s
  end

  def self.python_bugzilla_installed?
    File.exists?(File.expand_path(CMD))
  end

  # Running "bugzilla login" generates the bugzilla cookies.
  # If that cookie file exists assume the user already logged in.
  def self.logged_in?
    File.exists?(COOKIES_FILE)
  end

  def self.clear_login!
    File.delete(COOKIES_FILE) if File.exists?(COOKIES_FILE)
  end

  def self.login!(username = nil, password = nil)
    raise "Please install python-bugzilla" unless python_bugzilla_installed?
    return "Already Logged In" if self.logged_in?

    username ||= self.username
    password ||= self.password
    raise "username and password must be set" if username.nil? || password.nil?


    params = {}
    params["--bugzilla="] = bugzilla_request_uri
    params["--debug"]     = nil if debug_login
    params["login"]       = [username, password]

    begin
      login_cmd_result = LinuxAdmin.run!(CMD, :params => params)
    rescue => error
      # A failed login attempt could result in a corrupt COOKIES_FILE
      clear_login!
      raise "#{self.string_command(CMD, params, password)} Failed.\n#{error}"
    end

    return self.string_command(CMD, params, password), login_cmd_result.output
  end

  def self.query(product, flag=nil, bug_status=nil, output_format=nil)
    raise "Please install python-bugzilla" unless python_bugzilla_installed?
    raise ArgumentError, "product cannot be nil" if product.nil?

    params = {}
    params["--bugzilla="]     = bugzilla_request_uri
    params["query"]           = nil
    params["--product="]      = product
    params["--flag="]         = flag unless flag.nil?
    params["--bug_status="]   = bug_status unless bug_status.nil?
    params["--outputformat="] = output_format unless output_format.nil?

    begin
      query_cmd_result = LinuxAdmin.run!(CMD, :params => params)
    rescue => error
      raise "#{self.string_command(CMD, params)} Failed.\n#{error}"
    end

    return self.string_command(CMD, params), query_cmd_result.output
  end

  #
  # Example Usage:
  #
  #  bugids can be an Array of bug ids, a String or Fixnum
  #  containing a single bug id
  #
  #  options are a hash of options supported by python-bugzilla
  #
  #  Set the status of multiple bugs to RELEASE_PENDING:
  #  RubyBugzilla.modify([948970, 948971], :status => "RELEASE_PENDING")
  #
  #  Add a comment
  #  RubyBugzilla.modify("948972", :comment => "whatevs")
  #
  #  Set the status to POST and add a comment
  #  RubyBugzilla.modify(948970, :status => "POST", :comment => "Fixed in shabla")
  #
  def self.modify(bugids_arg, options)
    raise "Please install python-bugzilla" unless python_bugzilla_installed?

    bugids = Array(bugids_arg)
    if bugids.empty? || options.empty? || bugids_arg.to_s.empty?
      raise ArgumentError, "bugids and options must be specified"
    end

    params = {}
    params["--bugzilla="] = bugzilla_request_uri
    params["modify"]      = nil

    self.set_params_bugids(params, bugids)
    self.set_params_options(params, options)

    begin
      LinuxAdmin.run!(CMD, :params => params)
    rescue => error
      raise "#{self.string_command(CMD, params)} Failed.\n#{error}"
    end

    self.string_command(CMD, params)
  end

  private

  def self.set_params_options(params, options)
    options.each do |key,value|
      params["--#{key}="] = value
    end
  end

  def self.set_params_bugids(params, bugids)
    bugids.each do |bugid|
      params[bugid] = nil
    end
  end

  def self.string_command(cmd, params = {}, password=nil)
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
