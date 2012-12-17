# To run all tests at once, simply do:
#   bundle exec rake test
#
# To turn on more verbose output:
#   bundle exec rake test TESTOPTS="--verbose"
#
require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
end
