module ActiveBugzilla
  class Base
    def self.service=(service)
      @@service = service
    end

    def self.service
      @@service
    end

    private

    def self.normalize_timestamp(timestamp)
      timestamp.respond_to?(:to_time) ? timestamp.to_time : nil
    end

    def normalize_timestamp(timestamp)
      self.class.normalize_timestamp(timestamp)
    end
  end
end
