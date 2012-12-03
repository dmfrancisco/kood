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

  desc "board [OPTIONS] [<BOARD-ID>]", "Display and manage boards"
  #
  # Delete a board. If <board-id> is present, the specified board will be deleted.
  # With no arguments, the currently checked out board will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Clone a board. <board-id> will be cloned to <new-board-id>.
  # <board-id> is kept intact and a new one is created with the exact same data.
  method_option :clone, :aliases => '-c', :type => :string
  def board(board_id = nil)
    user = Kood::User.current

    # If no arguments and options are specified, the command displays all existing boards
    if board_id.nil? and options.empty?
      error "No boards were found." if user.boards.empty?
      puts user.boards.map { |b| (b.is_current? ? "* " : "  ") + b.id }

    # If the <board-id> argument is present without options, a new board will be created
    elsif options.empty?
      board = user.boards.create(id: board_id)
      if user.boards.size == 1
        board.checkout
        ok "Board created and checked out."
      else
        ok "Board created."
      end
    else
      board = board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)

      if options.key? 'clone'
        # TODO
      end # The cloned board may be deleted now, if the :delete option is present

      if options.key? 'delete'
        user.boards.destroy(board.id)
        ok "Board deleted."
      end
    end
  rescue
    error $!
  end
  map 'boards' => 'board'

  desc "checkout <BOARD-ID>", "Checkout a board"
  def checkout(board_id)
    Kood::Board.get!(board_id).checkout
    ok "Board checked out."
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

  desc "list [OPTIONS] [<LIST-ID>]", "Display and manage lists"
  #
  # Delete a list. If <list-id> is present, the specified list will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Clone a list. <list-id> will be cloned to <new-list-id>.
  # <list-id> is kept intact and a new one is created with the exact same data.
  method_option :clone, :aliases => '-c', :type => :string
  #
  # Move a list to another board. <list-id> will be moved to <board-id>.
  method_option :move, :aliases => '-m', :type => :string
  def list(list_id = nil)
    current_board = Kood::Board.current!

    # If no arguments and options are specified, the command displays all existing lists
    if list_id.nil? and options.empty?
      error "No lists were found." if current_board.lists.empty?
      puts current_board.lists.map { |l| l.id }

    # If the <list-id> argument is present without options, a new list will be created
    elsif options.empty?
      current_board.lists.create(id: list_id)
      ok "List created."

    else
      list = Kood::List.get!(list_id)

      if options.key? 'clone'
        # TODO
      end # The cloned list may be deleted or moved now

      if options.key? 'move'
        # TODO
        # If the list was moved, it cannot be deleted

      elsif options.key? 'delete'
        current_board.lists.destroy(list.id)
        ok "List deleted."
      end
    end
  rescue
    error $!
  end
  map 'lists' => 'list'

  # Invoked with `kood --help`, `kood help`, `kood help <cmd>` and `kood --help <cmd>`
  def help(cli = nil)
    case cli
      when nil then command = "kood"
      when "boards" then command = "kood-board"
      when "lists" then command = "kood-list"
      else command = "kood-#{cli}"
    end

    manpages = %w(
      kood-board
      kood-checkout
      kood-status
      kood-list)

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
