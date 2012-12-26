# -*- encoding: utf-8 -*-
require File.expand_path('../lib/kood/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name     = 'kood'
  gem.version  = Kood::VERSION
  gem.authors  = ['David Francisco']
  gem.email    = 'kood@dmfranc.com'
  gem.homepage = 'http://kood.dmfranc.com'
  gem.summary  = 'Work smarter -- An extensible CLI for git-backed taskboards.'
  gem.platform = Gem::Platform::RUBY
  gem.required_ruby_version = '>= 1.9.0'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "ronn",      "~> 0.7.0"
  gem.add_development_dependency "rake",      "~> 0.9.2"
  gem.add_runtime_dependency "activesupport", "~> 3.2.9"
  gem.add_runtime_dependency "thor",          "~> 0.16.0"
  gem.add_runtime_dependency "adapter-git",   "~> 0.5.0"
  gem.add_runtime_dependency "toystore",      "~> 0.10.4"
end
