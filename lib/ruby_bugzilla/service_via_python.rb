require 'awesome_spawn'

module RubyBugzilla
  class ServiceViaPython < ServiceBase
    CMD = `which bugzilla`.chomp
    COOKIES_FILE = File.expand_path('~/.bugzillacookies')

    def self.installed?
      File.exists?(CMD)
    end

    def initialize(bugzilla_uri, username, password)
      super
      raise "python-bugzilla not installed" unless installed?
      login
    end

    def installed?
      self.class.installed?
    end

    def clear_login!
      require 'fileutils'
      require 'tempfile'

      cookies_file_entry = "HttpOnly_.#{bugzilla_request_hostname}"

      if File.exists?(COOKIES_FILE)
        Tempfile.open('ruby_bugzilla') do |out_file|
          File.read(COOKIES_FILE).each_line do |line|
            out_file.puts(line) unless line.include?(cookies_file_entry)
          end
          out_file.close
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

    def query(options)
      raise ArgumentError, "options must be specified" if options.empty?

      params = {}
      params["query"] = nil
      set_params_options(params, options)

      execute_shell(params)
    end

    def modify(bug_ids, options)
      bug_ids = Array(bug_ids)
      raise ArgumentError, "bug_ids and options must be specified" if bug_ids.empty? || options.empty?
      raise ArgumentError, "bug_ids must be numeric" unless bug_ids.all? { |id| id.to_s =~ /^\d+$/ }

      params = {}
      params["modify"] = bug_ids
      set_params_options(params, options)

      execute_shell(params)
    end

    private

    def set_params_options(params, options)
      options.each do |key, value|
        params["--#{key}="] = value
      end
    end

    # Execute the command using AwesomeSpawn to execute python-bugzilla shell commands.
    def execute_shell(params)
      params = {"--bugzilla=" => bugzilla_request_uri}.merge(params)

      self.last_command = shell_command_string(CMD, params)
      AwesomeSpawn.run!(CMD, :params => params).output
    end

    # Build a printable representation of the python-bugzilla command executed.
    def shell_command_string(cmd, params)
      str = AwesomeSpawn.build_command_line(cmd, params)
      str.gsub(password.shellescape, "********")
    end
  end
end
