require 'thor'
require 'thor/group'
require_relative 'cli/table'

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

  desc "board [OPTIONS] [<BOARD-ID>]", "Display and manage boards"
  #
  # Delete a board. If <board-id> is present, the specified board will be deleted.
  # With no arguments, the current board will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Copy a board. <board-id> will be copied to <new-board-id>.
  # <board-id> is kept intact and a new one is created with the exact same data.
  method_option :copy, :aliases => '-c', :type => :string
  #
  # Create a board in an external repository.
  method_option :repo, :aliases => '-r', :type => :string
  def board(board_id = nil)
    # If no arguments and options are specified, the command displays all existing boards
    if board_id.nil? and no_method_options?
      return error "No boards were found." if Kood.config.boards.empty?

      max_board_id = Kood.config.boards.max_by { |b| b.id.size }.id.size
      Kood.config.boards.each do |b|
        marker     = b.is_current? ? "* " : "  "
        visibility = b.published?  ? "(shared)" : "(private)"
        puts marker + b.id.to_s.ljust(max_board_id + 2) +  set_color(visibility, :black)
      end

    # If the <board-id> argument is present without options, a new board will be created
    elsif no_method_options? or options.key? 'repo'
      board = Kood.config.boards.create(id: board_id, custom_repo: options['repo'])

      if Kood.config.boards.size == 1
        board.select
        ok "Board created and selected."
      else
        ok "Board created."
      end

    else
      board = board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)

      if options.key? 'copy'
        # TODO
      end # The copied board may be deleted now, if the :delete option is present

      if options.key? 'delete'
        Kood.config.boards.destroy(board.id)
        ok "Board deleted."
      end
    end
  rescue
    error $!
  end
  map 'boards' => 'board'

  desc "switch <BOARD-ID>", "Switches to the specified board"
  def switch(board_id)
    Kood::Board.get!(board_id).select
    ok "Board switched to #{ board_id }."
  rescue
    error $!
  end
  map 'select' => 'switch'

  desc "list [OPTIONS] [<LIST-ID>]", "Display and manage lists"
  #
  # Delete a list. If <list-id> is present, the specified list will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Copy a list. <list-id> will be copied to <new-list-id>.
  # <list-id> is kept intact and a new one is created with the exact same data.
  method_option :copy, :aliases => '-c', :type => :string
  #
  # Move a list to another board. <list-id> will be moved to <board-id>.
  method_option :move, :aliases => '-m', :type => :string
  def list(list_id = nil)
    Kood::Board.current!.with_context do |current_board|
      # If no arguments and options are specified, the command displays all existing lists
      if list_id.nil? and no_method_options?
        error "No lists were found." if current_board.lists.empty?
        puts current_board.list_ids

      # If the <list-id> argument is present without options, a new list will be created
      elsif no_method_options?
        current_board.lists.create(id: list_id)
        ok "List created."

      else
        list = Kood::List.get!(list_id)

        if options.key? 'copy'
          # TODO
        end # The copied list may be deleted or moved now

        if options.key? 'move'
          # TODO
          # If the list was moved, it cannot be deleted

        elsif options.key? 'delete'
          current_board.lists.destroy(list.id)
          ok "List deleted."
        end
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
  # Show status information of the current board associated with the given user.
  method_option :participant, :aliases => '-p', :type => :string
  #
  # Does the card action in the given list.
  method_option :list, :aliases => '-l', :type => :string
  #
  # Launches the configured editor to modify the card
  method_option :edit, :aliases => '-e', :type => :boolean
  #
  # Set and unset properties (add and remove are useful for properties that are arrays)
  method_option :set,    :aliases => '-s', :type => :hash
  method_option :unset,  :aliases => '-u', :type => :array
  method_option :add,    :aliases => '-a', :type => :array
  method_option :remove, :aliases => '-r', :type => :array
  def card(card_id_or_title = nil)
    Kood::Board.current!.with_context do |current_board|
      card_title = card_id = card_id_or_title

      # If no arguments and options are specified, the command displays all existing cards
      if card_title.nil? and no_method_options?
        return error "No lists were found." if current_board.lists.empty?
        print_board(current_board)

      # If the <card-title> argument is present without options, the card with the given
      # ID or title is displayed
      elsif card_id_or_title and no_method_options?
        card = Kood::Card.get_by_id_or_title!(card_id_or_title)
        print_card(current_board, card)

      else
        # If <card-title> and the `list` option are specified, a new card is created
        if card_title and options.key? 'list'
          list = Kood::List.get! options['list']
          list.cards.create(title: card_title)
          ok "Card created."
        end

        if options.key? 'copy'
          # TODO
        end # The copied card may be deleted or moved now

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
          return error "The specified card does not exist."
        end

        if options.key? 'edit'
          edit(card_id_or_title) # Execute the `edit` task
          return # The editor was openned - the following actions should not be triggered
        end

        if options.keys.any? { |option| ['set', 'unset', 'add', 'remove'].include? option }
          card = Kood::Card.get_by_id_or_title!(card_id_or_title)

          if options.key? 'set'
            options['set'].each do |key, value|
              value = Kood::Shell.try_convert(value) # Convert to float or int if possible

              if card.attributes.keys.include? key
                # card.attributes[k] = v # This doesn't seem to update the changed? property
                card.send("#{ key }=", value) # This alternative works as expected
              else
                card.more ||= {}
                # card.more[key] = value # This doesn't seem to update the changed? property
                card.more = card.more.merge({ key => value }) # This works as expected
              end
            end
          end

          if options.key? 'unset'
            # TODO Example: kood card lorem --unset title description labels
          end

          if options.key? 'add'
            # TODO Example: kood card lorem --add participants David Diogo -a labels bug
          end

          if options.key? 'remove'
            # TODO Example: kood card lorem --remove participants David
          end

          if card.changed?
            card.save!
            ok "Card updated."
          else
            error "No changes to persist."
          end
        end
      end
    end
  rescue
    error $!
  end
  map 'cards' => 'card'

  desc "edit [<CARD-ID|CARD-TITLE>]", "Launch the configured editor to modify the card"
  def edit(card_id_or_title = nil)
    Kood::Board.current!.with_context do |current_board|
      card = Kood::Card.get_by_id_or_title!(card_id_or_title)

      editor = [ ENV['KOOD_EDITOR'], ENV['EDITOR'] ].find { |e| !e.nil? && !e.empty? }

      if editor
        success, command = false, ""
        changed = card.edit_file do |filepath|
          command = "#{ editor } #{ filepath }"
          success = system(command)
        end

        if not success
          error "Could not run `#{ command }`."
        elsif changed
          ok "Card updated."
        else
          error "The editor exited without changes. Run `kood update` to persist changes."
        end
      else
        error "To edit a card set $EDITOR or $KOOD_EDITOR."
      end
    end
  rescue
    error $!
  end

  desc "update [<CARD-ID|CARD-TITLE>]", "Persist changes made to cards", hide: true
  def update(card_id_or_title = nil)
    Kood::Board.current!.with_context do |current_board|
      card = Kood::Card.get_by_id_or_title!(card_id_or_title)
      changed = card.edit_file

      if changed
        ok "Card updated."
      else
        error "No changes to persist."
      end
    end
  rescue
    error $!
  end

  desc "pull [<BOARD-ID>]", "Pull changes made to the board from the central server", hide: true
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def pull(board_id = nil)
    board = board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)
    exit_status, out, err = board.pull(options[:remote])

    if exit_status.zero? and out.include? "Already up-to-date"
      ok "Board already up-to-date."
    elsif exit_status.zero? # and out.include? "files changed"
      ok "Board updated successfully."
    else
      # Since this is an hidden and occasional command, print the original git error
      error "The following unexpected error was received from git:"
      error err.gsub('fatal: ', '')
    end
  rescue
    error $!
  end

  desc "push [<BOARD-ID>]", "Push changes made to the board to the central server", hide: true
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def push(board_id = nil)
    board = board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)
    exit_status, out, err = board.push(options[:remote])

    if exit_status.zero? and out.include? "Everything up-to-date"
      ok "Board in central server already up-to-date."
    elsif exit_status.zero?
      ok "Board in central server updated successfully."
    else
      # Since this is an hidden and occasional command, print the original git error
      error "The following unexpected error was received from git:"
      error err.gsub('fatal: ', '')
    end
  rescue
    error $!
  end

  desc "sync [<BOARD-ID>]", "Synchronize a board" # Only published branches can be synced
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def sync(board_id = nil)
    board = board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)
    exit_status, out, err = board.sync(options[:remote])

    if exit_status.zero? and out.include? "Everything up-to-date"
      ok "Board in central server already up-to-date."
    elsif exit_status.zero?
      ok "Board in central server updated successfully."
    else # An error occurred
      case err
      when /does not appear to be a git repository/
        error "You received the following error from git: \"#{ options[:remote] }\" " \
              "does not appear to be a git repository. \n" \
              "This may be because you have not set the \"#{ options[:remote] }\" " \
              "remote on your git repository. \n"
        remotes = board.adapter.client.remote_list
        if remotes.empty?
          error "Kood can't find any existing remotes."
        else
          error "Kood found the following remotes: #{ remotes.join('; ') }"
        end
      else
        error "The following unexpected error was received from git:"
        error err.gsub('fatal: ', '')
      end
    end
  rescue
    error $!
  end

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

  def print_board(board)
    num_lists = board.list_ids.size
    header = Kood::Table.new(num_lists)
    body   = Kood::Table.new(num_lists)

    board.lists.each do |list|
      header.new_column.add_row(list.id, align: 'center')

      column = body.new_column
      list.cards.each do |card|
        column.add_row(card.title, separator: false)
        column.add_row(card.id.slice(0, 8), color: 'black')
      end
    end

    title = Kood::Table.new(1, body.width)
    title.new_column.add_row(board.id, align: 'center')

    out = [ title.to_s(vertical_separator: false) ]
    out << header.separator('first') << header
    out << body.separator('middle') << body << body.separator('last')

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts out.join("\n")
  end

  def print_card(board, card)
    # The board's table may not use all terminal's horizontal space. In order to keep
    # things visually similar / aligned, the card table should have the same width.
    width = Kood::Table.new(board.list_ids.size).width

    table = Kood::Table.new(1, width)
    col = table.new_column
    col.add_row(card.title, separator: (!card.content.empty? or card.has_custom_attrs?))
    col.add_row(card.content) unless card.content.empty?
    col.add_row(card.printable_attrs) if card.has_custom_attrs?
    col.add_row("#{ card.id } (created at #{ card.date })", color: 'black')

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts [table.separator('first'), table, table.separator('last')].join("\n")
  end

  def no_method_options?
    (options.keys - self.class.class_options.keys).empty?
  end

  def set_color(text, *colors)
    if options.key? 'no-color'
      text
    else
      super
    end
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
program = File.basename $PROGRAM_NAME
command = ARGV.first
if program.eql? 'kood' # File is being imported from the bin and not from the test suite
  unless command.nil? or Kood::CLI.method_defined? command # Check if command is unknown
    begin
      plugin_name = command # The command is the name of the plugin

      # Require the plugin, which must be accessible and follow the naming convention
      require "kood-plugin-#{ plugin_name }"

      # Transform plugin name to a valid class name (for example, foo_bar becomes FooBar)
      plugin_class_name = Thor::Util.camel_case(plugin_name)

      # Get the class and register it (the plugin must extend Thor)
      plugin_class = Kood::Plugin.const_get(plugin_class_name)
      Kood::CLI.register(plugin_class, plugin_name, plugin_name, "Kood plugin")
    rescue LoadError
      # TODO Thor supports partial subcommands and aliases for subcommands. The
      # `method_defined?` condition is not enough. For now, we don't exit here and
      # everything should still work as expected, but this could be improved.
      #
      # puts "Could not find command or plugin \"#{ plugin_name }\"."
    end
  end
end

# Warn users that non-ascii characters in the arguments may cause errors
if ARGV.any? { |arg| not arg.ascii_only? }
  puts "For now, please avoid non-ascii characters. We're still working on providing" \
    " full support for utf-8 encoding."
end
