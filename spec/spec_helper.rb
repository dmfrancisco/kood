require 'minitest/autorun'
require 'kood'

module Kood
  # Prevent memoization in order to run the command suite multiple times
  def clean_repo
    @_repo = nil
  end
end

# Shortand to execute thor commands and capture its output
def kood(*cmds)
  return capture_io { Kood::CLI.start cmds.first.split }.join if cmds.size == 1

  stdout, stderr = [], []
  cmds.each do |cmd|
    out, err = capture_io { Kood::CLI.start cmd.split }
    stdout << out; stderr << err
  end
  return stdout, stderr
end
