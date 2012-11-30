require "thor"

class Kood::CLI < Thor
  namespace :kood

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

  desc "board [OPTIONS] [<BOARD-SLUG>]", "Display and manage boards"
  #
  # Delete a board. If <board-slug> is present, the specified board will be deleted.
  # With no arguments, the currently checked out board will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Clone a board. <board-slug> will be cloned to <new-board-slug>.
  # <board-slug> is kept intact and a new one is created with the exact same data.
  method_option :clone, :aliases => '-c', :type => :string
  def board(board_slug = nil)
    # If no arguments and options are specified, the command displays all existing boards
    if board_slug.nil? and options.empty?
      error "No boards were found." if Kood.boards.empty?
      puts Kood.boards.map { |b| (Kood.current_board == b.slug ? "* " : "  ") + b.slug }
      return
    end

    board_slug = Kood.current_board if board_slug.nil?

    # If the <board-slug> argument is present without options, a new board will be created
    if options.empty?
      Kood.create_board(board_slug)
      ok "Board created."
      return
    end

    if options.key? 'clone'
      # TODO
    end # The cloned board may be deleted now, if the :delete option is present

    if options.key? 'delete'
      # TODO
    end
  rescue
    error $!
  end
  map 'boards' => 'board'

  desc "checkout <BOARD-SLUG>", "Checkout a different board"
  def checkout(board_slug)
    Kood.checkout(board_slug)
  rescue
    error $!
  end

  desc "status", "Show the status of the currently checked out board"
  #
  # Show status information of the checked out board associated with the given user.
  method_option :assigned, :aliases => '-a', :type => :string
  def status
    # TODO
  rescue
    error $!
  end

  # Invoked with `kood --help`, `kood help`, `kood help <cmd>` and `kood --help <cmd>`
  def help(cli = nil)
    case cli
      when nil then command = "kood"
      when "boards" then command = "kood-board"
      else command = "kood-#{cli}"
    end

    manpages = %w(
      kood-board
      kood-checkout
      kood-status)

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

  def ok(text)
    # This idea comes from `git.io/logbook`, which is awesome. You should check it out.
    say text, :green
  end

  def error(text)
    say text, :red
  end
end
