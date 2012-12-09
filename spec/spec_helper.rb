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

# Shortand to execute thor commands and capture its output
def kood(*cmds)
  return capture_io { Kood::CLI.start cmds.first.shellsplit }.join if cmds.size == 1

  stdout, stderr = [], []
  cmds.each do |cmd|
    out, err = capture_io { Kood::CLI.start cmd.shellsplit }
    stdout << out; stderr << err
  end
  return stdout, stderr
end
