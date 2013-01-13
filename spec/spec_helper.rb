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

module Adapter
  module UserConfigFile
    def self.clear_conf
      config_file = Kood::KOOD_ROOT.join(Kood.config_path)
      File.delete(config_file) if File.exist?(config_file)
      @@conf = nil
    end
  end
end

module Kood
  module Shell
    def set_terminal_size(width = 1024, height = 768)
      @@size = [width, height]
    end

    def terminal_size
      @@size || [1024, 768]
    end
  end
end

def set_env(vars)
  vars.each_pair do |key, value|
    ENV[key.to_s] = value
  end
end

# Shortcut to execute thor commands and capture its output
def kood_colored(*cmds)
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

def kood(*cmds)
  cmds.map! { |cmd| cmd += " --no-color" }
  kood_colored(*cmds)
end
