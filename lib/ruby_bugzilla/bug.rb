module RubyBugzilla
  class Bug < Base
    attr_reader :id

    def initialize(id, attributes = {})
      @id         = id
      @attributes = normalize_attributes_from_xmlrpc(attributes.dup) unless attributes.empty?
    end

    def respond_to_missing?(meth, *args)
      attribute_names.include?(meth.to_s)
    end

    def method_missing(meth, *args, &block)
      attribute_name = meth.to_s
      if attribute_names.include?(attribute_name)
        attributes[attribute_name]
      else
        super
      end
    end

    def comments
      @comments ||= attributes['comments'].sort_by(&:count).collect { |hash| Comment.new(hash) }
    end

    def flags
      @flags ||= attributes['flags'].collect { |hash| Flag.new(hash.merge('bug_id' => @id)) }
    end

    def attribute_names
      @attribute_names ||= attributes.keys.sort
    end

    def self.find(options = {})
      options = normalize_attributes_to_xmlrpc(options)
      service.xmlrpc_service.search(options).collect do |bug_hash|
        Bug.new(bug_hash['id'], bug_hash)
      end
    end

    private

    ATTRIBUTE_RENAMES = {
      #   Bug       =>  XMLRPC
      :created_by   => :creator,
      :duplicate_id => :dupe_of,
    }

    TIMESTAMP_RENAMES = {
      #   Bug     =>    XMLRPC
      :created_on => :creation_time,
      :updated_on => :last_change_time,
    }

    def service
      self.class.service
    end

    def raw_data
      @raw_data ||= service.get(@id).first
    end

    def self.normalize_attributes_to_xmlrpc(hash)
      (TIMESTAMP_RENAMES.to_a + ATTRIBUTE_RENAMES.to_a).each do |bug_key, xmlrpc_key|
        hash[xmlrpc_key] = hash.delete(bug_key)
      end

      hash.delete_if { |k, v| v.nil? }
      hash
    end

    def normalize_attributes_from_xmlrpc(hash)
      TIMESTAMP_RENAMES.each do |bug_key, xmlrpc_key|
        hash[bug_key.to_s] = normalize_timestamp(hash.delete(xmlrpc_key.to_s))
      end

      ATTRIBUTE_RENAMES.each do |bug_key, xmlrpc_key|
        hash[bug_key.to_s] = hash.delete(xmlrpc_key.to_s)
      end

      hash.delete_if { |k, v| v.nil? }
      hash
    end

    def attributes
      @attributes ||= normalize_attributes_from_xmlrpc(raw_data)
    end
  end
end
