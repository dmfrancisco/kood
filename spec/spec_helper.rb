require 'minitest/autorun'
require 'kood'

module Kood
  # Prevent memoization in order to run the command suite multiple times
  def clear_repo
    @repo = {}
  end
end

class Kood::Config
  def self.clear_instance
    @@instance = nil
  end
end

# Shortcut to execute thor commands and capture its output
def kood(*cmds)
  quick_test = ENV["KOOD_TEST_OPTS"].to_s.include? '--quick'
  bin = File.expand_path('../../bin/kood', __FILE__)
  cmds.map! { |cmd| cmd += " --no-color" }
  stdout = stderr = []

  # If only one command was passed, return stdout if successful or stderr otherwise
  if cmds.size == 1
    if quick_test
      out, err = capture_io { Kood::CLI.start cmds.first.shellsplit }
      return err.empty? ? out.chomp : err.chomp
    else
      stdin, out, err = Open3.popen3("#{ bin } #{ cmds.first }")
      err = err.readlines.join.chomp
      return err.empty? ? out.readlines.join.chomp : err
    end
  end

  # If several commands were passed, return stdout and stderr for each one
  cmds.each do |cmd|
    if quick_test
      out, err = capture_io { Kood::CLI.start cmd.shellsplit }
      stdout << out
      stderr << err
    else
      stdin, out, err = Open3.popen3("#{ bin } #{ cmd }")
      stdout << out.readlines.join.chomp
      stderr << err.readlines.join.chomp
    end
  end
  return stdout, stderr
end
