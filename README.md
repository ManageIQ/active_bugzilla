# ActiveBugzilla

[![Gem Version](https://badge.fury.io/rb/active_bugzilla.png)](http://badge.fury.io/rb/active_bugzilla)
[![Build Status](https://travis-ci.org/ManageIQ/active_bugzilla.png)](https://travis-ci.org/ManageIQ/active_bugzilla)
[![Code Climate](https://codeclimate.com/github/ManageIQ/active_bugzilla.png)](https://codeclimate.com/github/ManageIQ/active_bugzilla)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/active_bugzilla/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/active_bugzilla)
[![Dependency Status](https://gemnasium.com/ManageIQ/active_bugzilla.png)](https://gemnasium.com/ManageIQ/active_bugzilla)

ActiveBugzilla is an ActiveRecord like interface to the Bugzilla API.

## Installation

Add this line to your application's Gemfile:

    gem 'active_bugzilla'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_bugzilla

## Example Usage

```ruby
service = ActiveBugzilla::Service.new("http://uri.to/bugzilla", username, password)
ActiveBugzilla::Base.service = service
bugs = ActiveBugzilla::Bug.find(:product => product_name, :status => "NEW")
bugs.each do |bug|
  puts "Bug ##{bug.id} - created_on=#{bug.created_on}, updated_on=#{bug.updated_on}, priority=#{bug.priority}"
  puts "Bug Attributes: #{bug.attribute_names.inspect}"
end

bug = ActiveBugzilla::Bug.find(:id => 12345)
puts "PRIORITY: #{bug.priority}"   # => "low"
puts "FLAGS: #{bug.flags.inspect}" # => {"devel_ack"=>"?", "qa_ack"=>"+"}
bug.priority = "high"
bug.flags.delete("qa_ack")
bug.flags["devel_ack"] = "+"
bug.save
puts "PRIORITY: #{bug.priority}"   # => "high"
puts "FLAGS: #{bug.flags.inspect}" # => {"devel_ack"=>"+"}
puts "FLAG OBJECTS: #{bug.flag_objects.inspect}" # => Array of ActiveBugzilla:Flag objects

bug.add_comment("Testing")
puts "COMMENTS: #{bug.comments.inspect}" # => Array of ActiveBugzilla:Comment objects
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
