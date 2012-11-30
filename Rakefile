require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV["RACK_ENV"] = "test"
  t.libs << "spec"
  t.pattern = "spec/**/*_spec.rb"
end
