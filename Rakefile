#!/usr/bin/env rake

# To run all specs at once, simply do:
#   bundle exec rake spec
#
# To turn on more verbose output:
#   bundle exec rake spec TESTOPTS="--verbose"
#
# To run unit tests:
#   bundle exec rake unit
#
# For additional help:
#   rake -T
#
require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:spec) do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
end

Rake::TestTask.new do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

desc "Uninstall the current version of kood"
task :uninstall do
  puts `gem uninstall -x kood` # -x flag uninstalls executables too without confirmation
end
