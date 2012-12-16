# To run all tests at once, simply do:
#   bundle exec rake test
#
# To turn on more verbose output:
#   bundle exec rake test TESTOPTS="--verbose"
#
# Kood-cli is built with Thor, which maps the CLI onto a class. With the --quick option,
# commands are simulated for faster execution:
#   bundle exec rake test KOOD_TEST_OPTS="--quick"
#
require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
end
