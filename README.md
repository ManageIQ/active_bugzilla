# ActiveBugzilla

[![Gem Version](https://badge.fury.io/rb/active_bugzilla.png)](http://badge.fury.io/rb/active_bugzilla)
[![Build Status](https://travis-ci.org/ManageIQ/active_bugzilla.png)](https://travis-ci.org/ManageIQ/active_bugzilla)
[![Code Climate](https://codeclimate.com/github/ManageIQ/active_bugzilla.png)](https://codeclimate.com/github/ManageIQ/active_bugzilla)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/active_bugzilla/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/active_bugzilla)
[![Dependency Status](https://gemnasium.com/ManageIQ/active_bugzilla.png)](https://gemnasium.com/ManageIQ/active_bugzilla)

ActiveBugzilla is an ActiveRecord like interface to the Bugzilla API.

## Prerequisites

python-bugzilla must be installed.

* For Fedora/RHEL
  * sudo yum install python-bugzilla
* For Mac
  * Download python-bugzilla from https://fedorahosted.org/python-bugzilla/
  * Untar the file
  * Run sudo setup.py install

python-bugzilla uses pycurl and expects it to be installed.

* For Mac
  * Download pycurl from http://pycurl.sourceforge.net/download/
  * Untar the file
  * Run sudo setup.py install

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
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
