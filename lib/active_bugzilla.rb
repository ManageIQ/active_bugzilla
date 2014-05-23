require 'active_bugzilla/version'

require 'active_bugzilla/service'

require 'active_bugzilla/base'
require 'active_bugzilla/bug'
require 'active_bugzilla/comment'
require 'active_bugzilla/field'
require 'active_bugzilla/flag'

module ActiveBugzilla
  # Convenience method for accessing ActiveBugzilla::Base.service.execute
  class << self
    def execute(command, params)
      self::Base.service.execute(command, params)
    end
    alias_method :call, :execute
  end
end
