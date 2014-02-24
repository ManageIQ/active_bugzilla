# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_bugzilla/version'

Gem::Specification.new do |spec|
  authors_hash = {
    "Joe VLcek"  => "jvlcek@redhat.com",
    "Jason Frey" => "jfrey@redhat.com",
  }

  spec.name          = "ruby_bugzilla"
  spec.version       = RubyBugzilla::VERSION
  spec.authors       = authors_hash.keys
  spec.email         = authors_hash.values
  spec.description   = %q{RubyBugzilla is a Ruby wrapper around the python-bugzilla CLI for easy access to the Bugzilla API.}
  spec.summary       = %q{RubyBugzilla is a Ruby wrapper around the python-bugzilla CLI for easy access to the Bugzilla API.}
  spec.homepage      = "http://github.com/ManageIQ/ruby_bugzilla"
  spec.license       = "MIT"

  spec.files         = `git ls-files -- lib/*`.split("\n")
  spec.files        += %w[README.md LICENSE.txt]
  spec.executables   = `git ls-files -- bin/*`.split("\n")
  spec.test_files    = `git ls-files -- spec/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"

  spec.add_dependency "awesome_spawn", "~> 1.0.0"
end
