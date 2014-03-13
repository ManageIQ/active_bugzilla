module ActiveBugzilla
  class Field < Base
    attr_reader  :display_name, :id, :name, :original_name, :type, :values, :visibility_field, :visibility_values
    attr_reader  :is_custom, :is_mandatory, :is_on_bug_entry
    alias_method :mandatory?,    :is_mandatory
    alias_method :custom?,       :is_custom
    alias_method :on_bug_entry?, :is_on_bug_entry

    KNOWN_TIMESTAMPS = %w(creation_time last_change_time)

    # List of field aliases. Maps old style RHBZ parameter names to actual
    # upstream values. Used for createbug() and query include_fields at
    # least.
    FIELD_ALIASES = {
      # old               => current
      'short_desc'        => 'summary',
      'comment'           => 'description',
      'rep_platform'      => 'platform',
      'bug_severity'      => 'severity',
      'bug_status'        => 'status',
      'bug_id'            => 'id',
      'blockedby'         => 'blocks',
      'blocked'           => 'blocks',
      'dependson'         => 'depends_on',
      'reporter'          => 'creator',
      'bug_file_loc'      => 'url',
      'dupe_id'           => 'dupe_of',
      'dup_id'            => 'dupe_of',
      'longdescs'         => 'comments',
      'opendate'          => 'creation_time',
      'creation_ts'       => 'creation_time',
      'status_whiteboard' => 'whiteboard',
      'delta_ts'          => 'last_change_time',
    }

    def initialize(attributes = {})
      @display_name      = attributes["display_name"]
      @id                = attributes["id"]
      @name              = self.class.field_alias(attributes["name"])
      @original_name     = attributes["name"]
      @type              = attributes["type"]
      @values            = attributes["values"]
      @visibility_field  = attributes["visibility_field"]
      @visibility_values = attributes["visibility_values"]
      @is_custom         = attributes["is_custom"]
      @is_mandatory      = attributes["is_mandatory"]
      @is_on_bug_entry   = attributes["is_on_bug_entry"]
    end

    def timestamp?
      (type == 5) || KNOWN_TIMESTAMPS.include?(name)
    end

    def self.instantiate_from_raw_data(data)
      data.delete_if { |hash| hash["name"] == "longdesc" } # Another way to specify comment[0]
      data.delete_if { |hash| hash["name"].include?(".") } # Remove things like longdescs.count
      data.collect do |field_hash|
        new(field_hash)
      end
    end

    private

    def self.field_alias(value)
      FIELD_ALIASES[value] || value
    end
  end
end
