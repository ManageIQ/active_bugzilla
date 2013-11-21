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

  attr_accessor :username, :password, :bugzilla_uri, :debug_login, :last_command

  def initialize(username, password, options = {})
    raise "python-bugzilla not installed" unless self.class.installed?
    raise ArgumentError, "username and password must be set" if username.nil? || password.nil?

    self.username     = username
    self.password     = password
    self.bugzilla_uri = options[:bugzilla_uri] || "https://bugzilla.redhat.com"
    self.debug_login  = options[:debug_login]
  end

  def login
    if self.class.logged_in?
      self.last_command = nil
      return "Already Logged In"
    end

    params = {}
    params["--debug"] = nil if debug_login
    params["login"]   = [username, password]

    begin
      execute(params)
    rescue
      self.class.clear_login! # A failed login attempt could result in a corrupt COOKIES_FILE
      raise
    end
  end

  def query(product, flag=nil, bug_status=nil, output_format=nil)
    raise ArgumentError, "product cannot be nil" if product.nil?

    params = {}
    params["query"]           = nil
    params["--product="]      = product
    params["--flag="]         = flag unless flag.nil?
    params["--bug_status="]   = bug_status unless bug_status.nil?
    params["--outputformat="] = output_format unless output_format.nil?

    execute(params)
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
  def modify(bugids_arg, options)
    bugids = Array(bugids_arg)
    if bugids.empty? || options.empty? || bugids_arg.to_s.empty?
      raise ArgumentError, "bugids and options must be specified"
    end

    params = {}
    params["modify"] = bugids
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
