# Ensure we require the local version and not one we might have installed already
require File.join([File.dirname(__FILE__), 'lib', 'kood', 'version.rb'])

spec = Gem::Specification.new do |s|
  s.name     = 'kood'
  s.version  = Kood::VERSION
  s.author   = 'David Francisco'
  s.email    = 'hello@dmfranc.com'
  s.homepage = 'http://dmfranc.com'
  s.platform = Gem::Platform::RUBY
  s.summary  = 'CLI for taskboards with a minimal self-hosted web interface'

  s.files = ["bin/kood", "lib/kood/version.rb", "lib/kood.rb"]
  s.require_paths << 'lib'
  s.bindir = 'bin'
  s.executables << 'kood'

  s.add_development_dependency "ronn"
  s.add_development_dependency "rake"
  s.add_runtime_dependency "thor", "0.16.0"
  s.add_runtime_dependency "toystore", "0.10.4"
end
