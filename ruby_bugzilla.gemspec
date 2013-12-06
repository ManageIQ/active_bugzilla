# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_bugzilla/version'

Gem::Specification.new do |spec|

  authors_hash = {"Joe VLcek"=>"jvlcek@redhat.com"}

  spec.name          = "ruby_bugzilla"
  spec.version       = RubyBugzilla::VERSION
  spec.authors       = authors_hash.keys
  spec.email         = authors_hash.values
  spec.description   = %q{
RubyBugzilla is a ruby wrapper around the python-bugzilla CLI for easy access to
the Bugzilla API from Ruby.}
  spec.summary       = %q{RubyBugzilla is a ruby wrapper around python-bugzilla}
  spec.description   = %q{
RubyBugzilla is a module allowing access the to python-bugzilla command
from Ruby.
}
  spec.summary       = %q{RubyBugzilla is a module providing a Ruby interface to python-bugzilla.}
  spec.homepage      = "http://github.com/ManageIQ/ruby-bugzilla"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
  
  spec.add_dependency "linux_admin", "~> 0.2.1"
end
