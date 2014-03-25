require 'active_support/concern'
require 'dirty_hashy'

module ActiveBugzilla::Bug::FlagsManagement
  extend ActiveSupport::Concern

  def flag_objects
    @flag_objects ||= ActiveBugzilla::Flag.instantiate_from_raw_data(raw_flags, @id)
  end

  def flags=(value)
    flags_will_change! unless value == @flags
    @flags = value
  end

  def flags
    @flags ||= begin
      flags_hash = flag_objects.each_with_object(DirtyIndifferentHashy.new) do |flag, hash|
        hash[flag.name] = flag.status
      end
      flags_hash.clean_up!
      flags_hash
    end
  end

  def self.flags_from_raw_flags_data(raw_flags_data)
    return {} if raw_flags_data.nil?
    flag_objects = ActiveBugzilla::Flag.instantiate_from_raw_data(raw_flags_data)
    flag_objects.each_with_object({}) do |flag, hash|
      hash[flag.name] = flag.status
    end
  end

  def flags_raw_updates
    raw_updates = []
    flags.changes.each do |key, value|
      _old_status, new_status = value
      new_status ||= 'X'
      raw_updates << {'name' => key.to_s, "status" => new_status}
    end
    raw_updates
  end

  def reset_flags
    @flag_objects = nil
    @flags        = nil
    flags
  end

  def changed_with_flags?
    changed_without_flags? || flags.changed?
  end

  def changes_with_flags
    changes = changes_without_flags
    changes['flags'] = [flags_previous_value, flags] if flags.changed?
    changes
  end

  def flags_previous_value
    previous_flags = flags.dup
    flags.changes.each do |key, value|
      previous_flags[key] = value.first
    end
    previous_flags
  end

  def changed_attributes_with_flags
    changed_attributes = changed_attributes_without_flags
    changed_attributes['flags'] = flags_previous_value if flags.changed?
    changed_attributes
  end

  included do
    define_attribute_methods [:flags]

    alias_method :changed_without_flags?, :changed?
    alias_method :changed?, :changed_with_flags?

    alias_method :changes_without_flags, :changes
    alias_method :changes, :changes_with_flags

    alias_method :changed_attributes_without_flags, :changed_attributes
    alias_method :changed_attributes, :changed_attributes_with_flags
  end
end
