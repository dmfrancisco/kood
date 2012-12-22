# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'kood', 'version.rb'])

Gem::Specification.new do |s|
  s.name     = 'kood'
  s.version  = Kood::VERSION
  s.author   = 'David Francisco'
  s.email    = 'kood@dmfranc.com'
  s.homepage = 'http://kood.dmfranc.com'
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.0'
  s.summary  = 'Work smarter -- An extensible CLI for git-backed taskboards.'

  s.files = `git ls-files`.split("\n")
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'kood'

  s.add_development_dependency "ronn"
  s.add_development_dependency "rake"
  s.add_runtime_dependency "thor", ">= 0.16.0"
  s.add_runtime_dependency "adapter-git", ">= 0.5.0"
  s.add_runtime_dependency "toystore", ">= 0.10.4"
end
