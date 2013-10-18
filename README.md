# RubyBugzilla


[![Gem Version](https://badge.fury.io/rb/ruby_bugzilla.png)](http://badge.fury.io/rb/ruby_bugzilla)
[![Build Status](https://travis-ci.org/ManageIQ/ruby_bugzilla.png)](https://travis-ci.org/ManageIQ/ruby_bugzilla)
[![Code Climate](https://codeclimate.com/github/ManageIQ/ruby_bugzilla.png)](https://codeclimate.com/github/ManageIQ/ruby_bugzilla)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/ruby_bugzilla/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/ruby_bugzilla)
[![Dependency Status](https://gemnasium.com/ManageIQ/ruby_bugzilla.png)](https://gemnasium.com/ManageIQ/ruby_bugzilla)

A Ruby wrapper around the python-bugzilla CLI for easy access to the Bugzilla API

## Installation

Add this line to your application's Gemfile:

    gem 'ruby_bugzilla'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby_bugzilla

## Usage

  If not already logged in to bugzilla, RubyBugzilla can login using
  the crendentials in bugzilla_credentials.yaml
  Copy sample/bugzilla_credentials.yaml to $HOME and edit the file
  to contain your bugzilla credentials.

  TODO: Write more usage instructions here


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
