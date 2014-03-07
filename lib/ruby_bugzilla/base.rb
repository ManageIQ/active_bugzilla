module RubyBugzilla
  class Base
    private

    def normalize_timestamp(timestamp)
      timestamp.respond_to?(:to_time) ? timestamp.to_time : nil
    end
  end
end
