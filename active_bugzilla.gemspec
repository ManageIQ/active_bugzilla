# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_bugzilla/version'

Gem::Specification.new do |spec|
  authors_hash = {
    "Joe VLcek"      => "jvlcek@redhat.com",
    "Jason Frey"     => "jfrey@redhat.com",
    "Oleg Barenboim" => "chessbyte@gmail.com",
  }

  spec.name          = "active_bugzilla"
  spec.version       = ActiveBugzilla::VERSION
  spec.authors       = authors_hash.keys
  spec.email         = authors_hash.values
  spec.description   = %q{ActiveBugzilla is an ActiveRecord like interface to the Bugzilla API.}
  spec.summary       = %q{ActiveBugzilla is an ActiveRecord like interface to the Bugzilla API.}
  spec.homepage      = "http://github.com/ManageIQ/active_bugzilla"
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
  spec.add_dependency "activemodel"
  spec.add_dependency "activesupport"
end
