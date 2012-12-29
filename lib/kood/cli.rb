require 'thor'
require 'thor/group'

require_relative 'cli/helpers/table'
require_relative 'cli/board'
require_relative 'cli/switch'
require_relative 'cli/sync'
require_relative 'cli/list'
require_relative 'cli/card'
require_relative 'cli/edit'
require_relative 'cli/plugin'

class Kood::CLI < Thor
  namespace :kood

  class_option 'debug', :desc => "Run Kood in debug mode", :type => :boolean
  class_option 'no-color', :desc => "Disable colorization in output", :type => :boolean

  check_unknown_options!

  # Thor help is not used for subcommands. Docs for each subcommand are written in the
  # man files.
  #
  # If the `default` key of `method_option` is a method, it will be executed each time
  # this program is called. As an alternative, a default value is specified inside each
  # method. So for example instead of:
  #
  #     method_option ... :default => foo()
  #     def bar(arg)
  #       ...
  #     end
  #
  # The following is done:
  #
  #     method_option ...
  #     def bar(arg)
  #       arg = foo() if arg.nil?
  #     end

  # Invoked with `kood --help`, `kood help`, `kood help <cmd>` and `kood --help <cmd>`
  def help(cli = nil)
    case cli
      when nil then command = "kood"
      when "boards" then command = "kood-board"
      when "select" then command = "kood-switch"
      when "lists"  then command = "kood-list"
      when "cards"  then command = "kood-card"
      else command = "kood-#{cli}"
    end

    manpages = %w(
      kood-board
      kood-switch
      kood-list
      kood-card)

    if manpages.include? command # Present a man page for the command
      root = File.expand_path("../../../man", __FILE__)
      exec "man #{ root }/#{ command }.1"
    else
      super # Use thor to output help
    end
  end

  desc "version", "Print kood's version information"
  map ['--version', '-v'] => :version
  def version
    puts "kood version #{ Kood::VERSION }"
  end

  private

  # Reimplement the `start` method in order to catch raised exceptions
  # For example, when running `kood c`, Thor will raise "Ambiguous task c matches ..."
  # FIXME Should not be necessary, since Thor catches exceptions when not in debug mode
  def self.start(given_args=ARGV, config={})
    Grit.debug = given_args.include?('--debug')
    super
  rescue Exception => e
    if given_args.include? '--debug'
      puts e.inspect
      puts e.backtrace
    elsif given_args.include? '--no-color'
      puts e
    else
      puts "\e[31m#{ e }\e[0m"
    end
  end

  def no_method_options?
    (options.keys - self.class.class_options.keys).empty?
  end

  def ok(text)
    # This idea comes from `git.io/logbook`, which is awesome. You should check it out.
    if options.key? 'no-color'
      puts text
    else
      say text, :green
    end
  end

  def error(text)
    if options.key? 'no-color'
      puts text
    else
      say text, :red
    end
  end
end

# Third-party commands (plugins)
#
Kood::CLI.load_plugins

# Warn users that non-ascii characters in the arguments may cause errors
#
if ARGV.any? { |arg| not arg.ascii_only? }
  puts "For now, please avoid non-ascii characters. We're still working on providing" \
    " full support for utf-8 encoding."
end
