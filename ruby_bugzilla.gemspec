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
  spec.description   = %q{The RubyBugzilla gem has been renamed to ActiveBugzilla and will no longer be supported.  See https://rubygems.org/gems/active_bugzilla}
  spec.summary       = %q{The RubyBugzilla gem has been renamed to ActiveBugzilla and will no longer be supported.  See https://rubygems.org/gems/active_bugzilla}
  spec.homepage      = "http://github.com/ManageIQ/active_bugzilla"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"

  spec.add_dependency "linux_admin", "~> 0.5.7"

  spec.post_install_message = <<-MESSAGE
  !    The RubyBugzilla gem has been renamed to ActiveBugzilla and will no longer be supported.
  !    See: https://rubygems.org/gems/active_bugzilla
  !    And: https://github.com/ManageIQ/active_bugzilla
  MESSAGE
end
