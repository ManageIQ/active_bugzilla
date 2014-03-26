require 'active_model'

module ActiveBugzilla
  class Bug < Base
    include ActiveModel::Validations
    include ActiveModel::Dirty

    require_relative 'bug/service_management'
    include ServiceManagement

    require_relative 'bug/flags_management'
    include FlagsManagement

    validates_numericality_of :id

    def initialize(attributes = {})
      attributes.each do |key, value|
        next unless attribute_names.include?(key)
        ivar_key = "@#{key}"
        instance_variable_set(ivar_key, value)
      end if attributes
    end

    def save
      return if changes.empty?
      update_attributes(changed_attribute_hash)
      @changed_attributes.clear
      reload
    end

    def reload
      raw_reset
      reset_instance_variables
      reset_flags
      @comments = Comment.instantiate_from_raw_data(raw_comments)
      self
    end

    def update_attributes(attributes)
      attributes.delete(:id)

      attributes.each do |name, value|
        symbolized_name = name.to_sym
        raise "Unknown Attribute #{name}" unless attribute_names.include?(symbolized_name)
        public_send("#{name}=", value)
        if symbolized_name == :flags
          attributes[name] = flags_raw_updates
        else
          @changed_attributes.delete(symbolized_name)
        end
      end

      raw_update(attributes) unless attributes.empty?
    end

    def update_attribute(key, value)
      update_attributes(key => value)
    end

    def comments
      @comments ||= Comment.instantiate_from_raw_data(raw_comments)
    end

    def add_comment(comment, is_private = false)
      _comment_id = service.add_comment(@id, comment, :is_private => is_private)
      reload
    end

    def self.fields
      @fields ||= Field.instantiate_from_raw_data(fetch_fields)
    end

    def self.find(options = {})
      options[:include_fields] ||= []
      options[:include_fields] << :id unless options[:include_fields].include?(:id)

      fields_to_include = options[:include_fields].dup

      search(options).collect do |bug_hash|
        fields_to_include.each do |field|
          bug_hash[field] = nil unless bug_hash.key?(field)
          bug_hash[field] = flags_from_raw_flags_data(bug_hash[field]) if field == :flags
        end
        Bug.new(bug_hash)
      end
    end

    private

    def reset_instance_variables
      attribute_names do |name|
        next if name == :id
        ivar_name = "@#{name}"
        instance_variable_set(ivar_name, raw_attribute(name))
      end
    end

    def changed_attribute_hash
      hash = {}
      changes.each do |key, values|
        _value_from, value_to = values
        hash[key.to_sym] = value_to
      end
      hash
    end
  end
end
