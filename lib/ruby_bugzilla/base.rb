module RubyBugzilla
  class Base
    def self.service=(service)
      @@service = service
    end

    def self.service
      @@service
    end

    private

    def normalize_timestamp(timestamp)
      timestamp.respond_to?(:to_time) ? timestamp.to_time : nil
    end
  end
end
