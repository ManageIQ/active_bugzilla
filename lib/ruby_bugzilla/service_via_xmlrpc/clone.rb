module RubyBugzilla
  class ServiceViaXmlrpc < ServiceBase
    CLONE_FIELDS = [
      :assigned_to,
      :cc,
      :cf_devel_whiteboard,
      :cf_internal_whiteboard,
      :comments,
      :component,
      :description,
      :groups,
      :keywords,
      :op_sys,
      :platform,
      :priority,
      :product,
      :qa_contact,
      :severity,
      :summary,
      :target_release,
      :url,
      :version,
      :whiteboard
    ]

    def clone(bug_id, overrides = {})
      raise ArgumentError, "bug_id must be numeric" unless bug_id.to_s =~ /^\d+$/

      existing_bz = query(bug_id, CLONE_FIELDS).first

      clone_description, clone_comment_is_private = assemble_clone_description(existing_bz)

      params = {}
      CLONE_FIELDS.each do |field|
        next if field == :comments
        params[field] = existing_bz[field.to_s]
      end

      # Apply overrides
      overrides.each do |param, value|
        params[param] = value
      end

      # Apply base clone fields
      params[:cf_clone_of]        = bug_id
      params[:description]        = clone_description
      params[:comment_is_private] = clone_comment_is_private

      create(params)[:id.to_s]
    end

    private

    def assemble_clone_description(existing_bz)
      clone_description = " +++ This bug was initially created as a clone of Bug ##{existing_bz[:id]} +++ \n"
      clone_description << existing_bz[:description.to_s]

      clone_comment_is_private = false
      existing_bz[:comments.to_s].each do |comment|
        clone_description << "\n\n"
        clone_description << "*" * 70
        clone_description << "\nFollowing comment by %s on %s\n\n" %
          [comment['author'], comment['creation_time'].to_time]
        clone_description << "\n\n"
        clone_description << comment['text']
        clone_comment_is_private = true if comment['is_private']
      end

      [clone_description, clone_comment_is_private]
    end
  end
end
