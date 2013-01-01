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

def set_env(vars)
  vars.each_pair do |key, value|
    ENV[key.to_s] = value
  end
end

# Shortcut to execute thor commands and capture its output
def kood(*cmds)
  cmds.map! { |cmd| cmd += " --no-color" }
  stdout = stderr = []

  # If only one command was passed, return stdout if successful or stderr otherwise
  if cmds.size == 1
    out, err = capture_io { Kood::CLI.start cmds.first.shellsplit }
    return err.empty? ? out.chomp : err.chomp
  end

  # If several commands were passed, return stdout and stderr for each one
  cmds.each do |cmd|
    out, err = capture_io { Kood::CLI.start cmd.shellsplit }
    stdout << out
    stderr << err
  end
  return stdout, stderr
end
