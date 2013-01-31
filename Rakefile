#!/usr/bin/env rake

# To run all tests at once, simply do:
#   bundle exec rake test
#
# To run unit tests:
#   bundle exec rake test:unit
#
# To turn specs with verbose output:
#   bundle exec rake test:spec TESTOPTS="--verbose"
#
# For additional help:
#   rake --tasks
#
require 'rake/testtask'
require 'bundler/gem_tasks'

namespace :test do
  Rake::TestTask.new(:spec) do |t|
    ENV["RACK_ENV"] = "test"
    t.libs << "spec"
    t.pattern = "spec/**/*_spec.rb"
  end

  Rake::TestTask.new(:unit) do |t|
    ENV["RACK_ENV"] = "test"
    t.libs << "test"
    t.pattern = "test/**/*_test.rb"
  end

  task :all => [:unit, :spec]
end

desc "Run all test suites"
task :test => 'test:all'

desc "Uninstall the current version of kood"
task :uninstall do
  puts `gem uninstall -x kood` # -x flag uninstalls executables too without confirmation
end

task :default => :test
