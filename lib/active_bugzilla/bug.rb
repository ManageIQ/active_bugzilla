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
      @comments = Comment.instantiate_from_raw_data(raw_comments)
      @flags    = Flag.instantiate_from_raw_data(raw_flags, @id)
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
      @comments ||= Comment.instantiate_from_raw_data(raw_comments)
    end

    def add_comment(comment, is_private = false)
      comment_id = service.add_comment(@id, comment, :is_private => is_private)
      reload
    end

    def flags
      @flags ||= Flag.instantiate_from_raw_data(raw_flags, @id)
    end

    def self.fields
      @fields ||= Field.instantiate_from_raw_data(fetch_fields)
    end

    def self.find(options = {})
      options[:include_fields] ||= [:id]
      search(options).collect do |bug_hash|
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
        hash[key] = value_to
      end
      hash
    end
  end
end
