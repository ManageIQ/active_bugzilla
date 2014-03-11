module ActiveBugzilla
  class Field < Base
    attr_reader  :display_name, :id, :name, :type, :values, :visibility_field, :visibility_values
    attr_reader  :is_custom, :is_mandatory, :is_on_bug_entry
    alias_method :mandatory?,    :is_mandatory
    alias_method :custom?,       :is_custom
    alias_method :on_bug_entry?, :is_on_bug_entry

    def initialize(attributes = {})
      @display_name      = attributes["display_name"]
      @id                = attributes["id"]
      @name              = attributes["name"]
      @type              = attributes["type"]
      @values            = attributes["values"]
      @visibility_field  = attributes["visibility_field"]
      @visibility_values = attributes["visibility_values"]
      @is_custom         = attributes["is_custom"]
      @is_mandatory      = attributes["is_mandatory"]
      @is_on_bug_entry   = attributes["is_on_bug_entry"]
    end
  end
end
