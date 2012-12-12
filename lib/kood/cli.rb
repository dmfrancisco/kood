require "thor"
require_relative "cli/table"

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
  #
  # Create a board in an external repository.
  method_option :repo, :aliases => '-r', :type => :string
  def board(board_id = nil)
    # If no arguments and options are specified, the command displays all existing boards
    if board_id.nil? and options.empty?
      error "No boards were found." if Kood.config.boards.empty?
      puts Kood.config.boards.map { |b| (b.is_current? ? "* " : "  ") + b.id }

    # If the <board-id> argument is present without options, a new board will be created
    elsif options.empty? or options.key? 'repo'
      board = Kood.config.boards.create(id: board_id, custom_repo: options['repo'])

      if Kood.config.boards.size == 1
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
        Kood.config.boards.destroy(board.id)
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
      puts current_board.list_ids

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

  desc "card [OPTIONS] [<CARD-ID|CARD-TITLE>]", "Display and manage cards"
  #
  # Delete a card. If <card-title> is present, the specified card will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Show status information of the checked out board associated with the given user.
  method_option :assigned, :aliases => '-a', :type => :string
  #
  # Does the card action in the given list.
  method_option :list, :aliases => '-l', :type => :string
  #
  # Launches the configured editor to modify the card
  method_option :edit, :aliases => '-e', :type => :boolean
  def card(card_id_or_title = nil)
    card_title = card_id = card_id_or_title
    current_board = Kood::Board.current!

    # If no arguments and options are specified, the command displays all existing cards
    if card_title.nil? and options.empty?
      return error "No lists were found." if current_board.lists.empty?
      print_board(current_board)

    # If the <card-title> argument is present without options, the card with the given
    # ID or title is displayed
    elsif card_id_or_title and options.empty?
      card = Kood::Card.get_by_id_or_title!(card_id_or_title)
      puts "Title: #{ card.title }"

    # If the <card-title> argument is present without options despite the list, a new
    # card will be created
    elsif card_title and options.key? 'list'
      list = Kood::List.get! options['list']
      list.cards.create(title: card_title)
      ok "Card created."

    else
      if options.key? 'clone'
        # TODO
      end # The cloned card may be deleted or moved now

      if options.key? 'move'
        # TODO
        # If the card was moved, it cannot be deleted

      elsif options.key? 'delete'
        current_board.lists.each do |list|
          cards = list.cards.select { |c| c.id == card_id || c.title == card_title }
          if cards.size == 1 # If only 1 result, since there may be cards with same title
            card = cards.first
            list.cards.destroy(card.id)
            ok "Card deleted."
            return
          end
        end
        error "The specified card does not exist."

      elsif options.key? 'edit'
        edit(card_id_or_title) # Execute the `edit` task
      end
    end
  rescue
    error $!
  end
  map 'cards' => 'card'

  desc "edit [<CARD-ID|CARD-TITLE>]", "Launches the configured editor to modify the card"
  def edit(card_id_or_title = nil)
    current_board = Kood::Board.current!
    card = Kood::Card.get_by_id_or_title!(card_id_or_title)

    editor = ENV['KOOD_EDITOR'] || ENV['EDITOR']

    if editor
      changed = card.edit_file(current_board) do |filepath|
        `#{ editor } #{ filepath }`
      end

      if changed
        ok "Card updated."
      else
        error "The editor exited without changes. Run `kood update` to persist changes."
      end
    else
      error "To edit a card set $EDITOR or $BUNDLER_EDITOR"
    end
  end

  desc "update [<CARD-ID|CARD-TITLE>]", "Persists changes made to cards", hide: true
  def update(card_id_or_title = nil)
    current_board = Kood::Board.current!
    card = Kood::Card.get_by_id_or_title!(card_id_or_title)
    changed = card.edit_file(current_board)

    if changed
      ok "Card updated."
    else
      error "No changes to persist."
    end
  rescue
    error $!
  end

  # Invoked with `kood --help`, `kood help`, `kood help <cmd>` and `kood --help <cmd>`
  def help(cli = nil)
    case cli
      when nil then command = "kood"
      when "boards" then command = "kood-board"
      when "lists" then command = "kood-list"
      when "cards" then command = "kood-card"
      else command = "kood-#{cli}"
    end

    manpages = %w(
      kood-board
      kood-checkout
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

  def print_board(board)
    num_lists = board.list_ids.size
    title  = Kood::Table.new(1)
    header = Kood::Table.new(num_lists)
    body   = Kood::Table.new(num_lists)

    title.new_column.add_row(board.id, align: 'center')

    board.lists.each do |list|
      header.new_column.add_row(list.id, align: 'center')

      column = body.new_column
      list.cards.each do |card|
        column.add_row(card.id.slice(0, 7), separator: false, color: 'black')
        column.add_row(card.title)
      end
    end

    puts title.to_s(vertical_separator: false)
    puts header.separator('first')
    puts header
    puts body.separator('middle')
    puts body
    puts body.separator('last')
  end

  def ok(text)
    # This idea comes from `git.io/logbook`, which is awesome. You should check it out.
    say text, :green
  end

  def error(text)
    say text, :red
  end
end
