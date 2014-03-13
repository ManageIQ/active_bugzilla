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

    def comments
      @comments ||= raw_comments.sort_by(&:count).collect { |hash| Comment.new(hash) }
    end

    def flags
      @flags ||= raw_flags.collect { |hash| Flag.new(hash.merge('bug_id' => @id)) }
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
  end
end
