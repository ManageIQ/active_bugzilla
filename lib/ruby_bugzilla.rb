require 'yaml'
require 'linux_admin'

class RubyBugzilla

  CMD = `which bugzilla`.chomp
  COOKIES_FILE = File.expand_path('~/.bugzillacookies')
  CREDS_FILE = File.expand_path('~/.bugzilla_credentials.yaml')

  def self.username=(un)
    @username = un
  end

  def self.username
    @username
  end

  def self.password=(pw)
    @password = pw
  end

  def self.password
    @password
  end

  def self.credentials(username = nil, password = nil)
    self.username = username
    self.password = password

    if self.username.nil? || self.password.nil?
      un_from_file, pw_from_file = self.credentials_from_file
      self.username ||= un_from_file
      self.password ||= pw_from_file
    end

    return self.username, self.password
  end

  # Ruby will catch and raise Erron::ENOENT: if there is no
  # ~/.bugzilla_credentials.yaml file.
  def self.credentials_from_file
    begin
      creds = YAML.load_file(CREDS_FILE)
    rescue Errno::ENOENT
      return nil, nil
    end

    return creds[:bugzilla_credentials][:username], creds[:bugzilla_credentials][:password]
  end

  def self.options
    begin
      options = YAML.load_file(CREDS_FILE)
    rescue Errno::ENOENT
      return "https://bugzilla.redhat.com/", false
    end

    return options[:bugzilla_options][:bugzilla_uri], options[:bugzilla_options][:debug]
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

    username, password = self.credentials(username, password)
    uri_opt, debug_opt = self.options

    params = {}
    params["--bugzilla="] = "#{uri_opt}/xmlrpc.cgi" unless uri_opt.nil?
    params["--debug"]     = nil if debug_opt
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

    uri_opt, _ = self.options

    params = {}
    params["--bugzilla="]     = "#{uri_opt}/xmlrpc.cgi" unless uri_opt.nil?
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

    uri_opt, _ = self.options

    params = {}
    params["--bugzilla="] = "#{uri_opt}/xmlrpc.cgi" unless uri_opt.nil?
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
