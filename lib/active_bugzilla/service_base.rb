module ActiveBugzilla
  class ServiceBase
    attr_accessor :bugzilla_uri, :username, :password, :last_command
    attr_reader   :bugzilla_request_uri, :bugzilla_request_hostname

    DEFAULT_FIELDS_TO_INCLUDE = [
      :actual_time,
      :alias,
      :assigned_to,
      :blocks,
      :cc,
      :classification,
      :comments,
      :component,
      :creator,
      :depends_on,
      :description,
      :dupe_of,
      :estimated_time,
      :flags,
      :keywords,
      :last_change_time,
      :platform,
      :priority,
      :product,
      :qa_contact,
      :remaining_time,
      :resolution,
      :severity,
      :status,
      :summary,
      :target_release,
      :url,
      :version,
    ]

    def self.timeout=(value)
      @@timeout = value
    end

    def self.timeout
      defined?(@@timeout) && @@timeout
    end

    def timeout
      self.class.timeout
    end

    def bugzilla_uri=(value)
      @bugzilla_request_uri      = URI.join(value, "xmlrpc.cgi").to_s
      @bugzilla_request_hostname = URI(value).hostname
      @bugzilla_uri              = value
    end

    def initialize(bugzilla_uri, username, password)
      raise ArgumentError, "username and password must be set" if username.nil? || password.nil?

      self.bugzilla_uri = bugzilla_uri
      self.username     = username
      self.password     = password
    end

    def inspect
      super.gsub(/@password=\".+?\", /, "")
    end
  end
end
