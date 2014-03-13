require 'active_model'

module ActiveBugzilla
  class Bug < Base
    include ActiveModel::Validations
    include ActiveModel::Dirty

    require_relative 'bug/service_management'
    include ServiceManagement

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
      @comments = get_comments
      @flags    = get_flags
      self
    end

    def update_attributes(attributes)
      attributes.delete(:id)

      attributes.each do |name, value|
        raise "Unknown Attribute #{name}" unless attribute_names.include?(name.to_sym)
        ivar_name = "@#{name}"
        instance_variable_set(ivar_name, value)
        @changed_attributes.delete(name)
      end

      raw_update(attributes) unless attributes.empty?
    end

    def update_attribute(key, value)
      update_attributes(key => value)
    end

    def comments
      @comments ||= get_comments
    end

    def flags
      @flags ||= get_flags
    end

    def self.fields
      @fields ||= fetch_fields.collect { |field_hash| Field.new(field_hash) }
    end

    def self.find(options = {})
      options[:include_fields] ||= [:id]
      search(options).collect do |bug_hash|
        Bug.new(bug_hash)
      end
    end

    private

    def reset_instance_variables
      self.attribute_names do |name|
        next if name == :id
        ivar_name = "@#{name}"
        instance_variable_set(ivar_name, raw_attribute(name))
      end
    end

    def changed_attribute_hash
      hash = {}
      changes.each do |key, values|
        value_from, value_to = values
        hash[key] = value_to
      end
      hash
    end

    def get_comments
      raw_comments.sort_by(&:count).collect { |hash| Comment.new(hash) }
    end

    def get_flags
      raw_flags.collect { |hash| Flag.new(hash.merge('bug_id' => @id)) }
    end
  end
end
