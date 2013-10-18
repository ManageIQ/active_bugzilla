require 'yaml'
require 'linux_admin'

class RubyBugzilla

  CMD = '/usr/bin/bugzilla'
  COOKIES_FILE = File.expand_path('~') + '/.bugzillacookies'
  CREDS_FILE = File.expand_path('~') + '/.bugzilla_credentials.yaml'

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

    [self.username, self.password]
  end

  # Ruby will catch and raise Erron::ENOENT: if there is no
  # ~/.bugzilla_credentials.yaml file.
  def self.credentials_from_file
    begin
      creds = YAML.load_file(CREDS_FILE)
    rescue Errno::ENOENT => error
      return [nil, nil]
    end

    [creds[:bugzilla_credentials][:username],
      creds[:bugzilla_credentials][:password]]
  end

  def self.options
    begin
      options = YAML.load_file(CREDS_FILE)
    rescue Errno::ENOENT => error
      return ["https://bugzilla.redhat.com/", false]
    end
    [options[:bugzilla_options][:bugzilla_uri],
      options[:bugzilla_options][:debug]]
  end

  # Running "bugzilla login" generates the bugzilla cookies.
  # If that cookie file exists assume the user already logged in.
  def self.logged_in?
    File.exists?(COOKIES_FILE)
  end

  def self.clear_login!
    if File.exists?(COOKIES_FILE) then
      File.delete(COOKIES_FILE)
    end
  end

  def self.login!(username = nil, password = nil)

    login_cmd = "#{CMD} "
    output = "Already Logged In"
    params = {}

    raise "Please install python-bugzilla" unless File.exists?(File.expand_path(CMD))

    unless self.logged_in?
      username, password = self.credentials(username, password)
      uri_opt, debug_opt = self.options

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
      output = login_cmd_result.output
    end
    [self.string_command(CMD, params, password), output]
  end

  def self.query(product, flag=nil, bug_status=nil, output_format=nil)

    raise "Please install python-bugzilla" unless
      File.exists?(File.expand_path(CMD))

    raise ArgumentError, "product cannot be nil" if product.nil?

    uri_opt, debug_opt = self.options

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

    [self.string_command(CMD, params), query_cmd_result.output]
  end

  private
  def self.string_command(cmd, params = {}, password=nil)
    scrubbed_str = str = ""
    str << cmd
    params.each do |param, value|
      if value.kind_of?(Array)
        str << " #{param} \"#{value.join(" ")}\" "
      else
        str << " #{param}\"#{value}\" "
      end
    end
    scrubbed_str = str.sub(password, "********") unless password.nil?
    scrubbed_str
  end

end
