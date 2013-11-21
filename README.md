# RubyBugzilla

[![Gem Version](https://badge.fury.io/rb/ruby_bugzilla.png)](http://badge.fury.io/rb/ruby_bugzilla)
[![Build Status](https://travis-ci.org/ManageIQ/ruby_bugzilla.png)](https://travis-ci.org/ManageIQ/ruby_bugzilla)
[![Code Climate](https://codeclimate.com/github/ManageIQ/ruby_bugzilla.png)](https://codeclimate.com/github/ManageIQ/ruby_bugzilla)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/ruby_bugzilla/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/ruby_bugzilla)
[![Dependency Status](https://gemnasium.com/ManageIQ/ruby_bugzilla.png)](https://gemnasium.com/ManageIQ/ruby_bugzilla)

A Ruby wrapper around the python-bugzilla CLI for easy access to the Bugzilla API

## Prerequisites

python-bugzilla must be installed.

* Download python-bugzilla from https://fedorahosted.org/python-bugzilla/
* Untar the file
* Run setup.py install

python-bugzilla uses pycurl and expects it to be installed.

* Download pycurl from http://pycurl.sourceforge.net/download/
* Untar the file
* Run setup.py install

## Installation

Add this line to your application's Gemfile:

    gem 'ruby_bugzilla'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby_bugzilla

## Example Usage

```ruby
bz = RubyBugzilla.new("http://uri.to/bugzilla, "username", "password")
bz.login
output = bz.query(:bug_status => "NEW")
bz.modify([928134, 932439], :status => "RELEASE_PENDING", :comment => "Looks good")
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
