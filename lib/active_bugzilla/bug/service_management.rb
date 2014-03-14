require 'active_support/concern'
module ActiveBugzilla::Bug::ServiceManagement
  extend ActiveSupport::Concern

  ATTRIBUTES_XMLRPC_RENAMES_MAP = {
    #   Bug       =>  XMLRPC
    :created_by   => :creator,
    :created_on   => :creation_time,
    :duplicate_id => :dupe_of,
    :updated_on   => :last_change_time,

    # Some are absent from what Bugzilla.fields() returns
    :actual_time  => :actual_time,
  }

  module ClassMethods
    def attributes_xmlrpc_map
      @attributes_xmlrpc_map ||= begin
        hash = generate_xmlrpc_map
        define_attributes(hash.keys)
        hash
      end
    end

    def xmlrpc_timestamps
      @xmlrpc_timestamps ||= fields.select(&:timestamp?).collect { |field| field.name.to_sym }
    end

    def default_service_attributes
      attributes_xmlrpc_map.values - [:comments]
    end

    def normalize_attributes_to_service(hash)
      attributes_xmlrpc_map.each do |bug_key, xmlrpc_key|
        next if bug_key == xmlrpc_key
        hash[xmlrpc_key] = hash.delete(bug_key)
      end

      hash[:include_fields] = normalize_include_fields_to_service(hash[:include_fields]) if hash.key?(:include_fields)

      hash.delete_if { |k, v| v.nil? }
      hash
    end

    def normalize_attributes_from_service(hash)
      attributes_xmlrpc_map.each do |bug_key, xmlrpc_key|
        value = hash.delete(xmlrpc_key.to_s)
        value = normalize_timestamp(value) if xmlrpc_timestamps.include?(xmlrpc_key)
        hash[bug_key] = value
      end

      hash
    end

    def attribute_names
      @attribute_names ||= attributes_xmlrpc_map.keys.sort_by { |sym| sym.to_s }
    end

    def search(options = {})
      options = normalize_attributes_to_service(options)
      service.search(options).collect do |bug_hash|
        normalize_attributes_from_service(bug_hash)
      end
    end

    private

    def fetch_fields
      service.fields
    end

    def generate_xmlrpc_map
      hash = ATTRIBUTES_XMLRPC_RENAMES_MAP
      fields.each do |field|
        next if hash.values.include?(field.name)
        next if field.name.include?(".")
        attribute_name = field.name
        attribute_name = attribute_name[3..-1] if attribute_name[0..2] == "cf_"
        hash[attribute_name.to_sym] = field.name.to_sym
      end
      hash
    end

    def normalize_include_fields_to_service(include_fields)
      include_fields.collect do |bug_key|
        attributes_xmlrpc_map[bug_key]
      end.uniq.compact
    end

    def define_attributes(names)
      define_attribute_methods names

      names.each do |name|
        ivar_name = "@#{name}"
        define_method(name) do
          return instance_variable_get(ivar_name) if instance_variable_defined?(ivar_name)
          instance_variable_set(ivar_name, raw_attribute(name))
        end

        define_method("#{name}=") do |val|
          public_send("#{name}_will_change!") unless val == instance_variable_get(ivar_name)
          instance_variable_set(ivar_name, val)
        end
      end
    end
  end

  def attribute_names
    self.class.attribute_names
  end

  private

  def service
    self.class.service
  end

  def raw_reset
    @raw_data       = nil
    @raw_comments   = nil
    @raw_flags      = nil
    @raw_attributes = nil
  end

  def raw_update(attributes)
    attributes = self.class.normalize_attributes_to_service(attributes)
    result = service.update(@id, attributes).first

    id = result['id']
    raise "Error - Expected to update id <#{@id}>, but updated <#{id}>" unless id == @id

    result
  end

  def raw_data
    @raw_data ||= service.get(@id, :include_fields => self.class.default_service_attributes).first
  end

  def raw_flags
    @raw_flags ||= raw_attribute('flags')
  end

  def raw_comments
    @raw_comments ||= (raw_attributes['comments'] || fetch_comments)
  end

  def raw_attributes
    @raw_attributes ||= self.class.normalize_attributes_from_service(raw_data)
  end

  def raw_attribute_get(key)
    raw_attributes
    @raw_attributes[key]
  end

  def raw_attribute_set(key, value)
    raw_attributes
    @raw_attributes[key] = value
  end

  def raw_attribute(key)
    raw_attribute_set(key, fetch_attribute(key)) unless raw_attributes.key?(key)
    raw_attribute_get(key)
  end

  def fetch_comments
    service.comments(:ids => @id)['bugs'][@id.to_s]['comments']
  end

  def fetch_attribute(key)
    service.get(@id, :include_fields => [key]).first[key]
  end
end
