#!/usr/bin/env rake

# To run all tests at once, simply do:
#   bundle exec rake test
#
# To turn on more verbose output:
#   bundle exec rake test TESTOPTS="--verbose"
#
# For additional help:
#   rake -T
#
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
end

desc "Uninstall the current version of kood"
task :uninstall do
  puts `gem uninstall -x kood` # -x flag uninstalls executables too without confirmation
end
