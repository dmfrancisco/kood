class Kood::CLI < Thor

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
      list_existing_boards

    # If the <board-id> argument is present without options, a new board will be created
    elsif no_method_options? or options.key? 'repo'
      create_board(board_id)

    # Since <board-id> is present, operate on the specified board
    else
      operate_on_board(board_id)
    end
  end
  map 'boards' => 'board'

  private

  def list_existing_boards
    return error "No boards were found." if Kood.config.boards.empty?

    max_board_id = Kood.config.boards.max_by { |b| b.id.size }.id.size
    Kood.config.boards.each do |b|
      marker     = b.is_current? ? "* " : "  "
      visibility = b.published?  ? "(shared)" : "(private)"
      visibility = set_color(visibility, :black, :bold) unless options.key? 'no-color'
      puts marker + b.id.to_s.ljust(max_board_id + 2) + visibility
    end
  end

  def create_board(board_id)
    board = Kood.config.boards.create(id: board_id, custom_repo: options['repo'])

    if Kood.config.boards.size == 1
      board.select
      ok "Board created and selected."
    else
      ok "Board created."
    end
  end

  def delete_board(board_id)
    Kood.config.boards.destroy(board_id)
    ok "Board deleted."
  end

  def get_board_or_current!(board_id)
    board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)
  end

  def operate_on_board(board_id)
    board = get_board_or_current!(board_id) # Raises exception if inexistent

    if options.key? 'copy'
      # TODO
    end # The copied board may be deleted now, if the :delete option is present

    if options.key? 'delete'
      delete_board(board_id)
    end
  end

  def print_board(board)
    opts = options.key?('no-color') ? {} : { color: [:black, :bold] }
    num_lists = board.list_ids.size
    header = Kood::Table.new(num_lists)
    body   = Kood::Table.new(num_lists)

    board.lists.each do |list|
      header.new_column.add_row(list.id, align: 'center')

      column = body.new_column
      list.cards.each do |card|
        column.add_row(card.title, separator: false)
        column.add_row(card.id.slice(0, 8), opts)
      end
    end

    title = Kood::Table.new(1, body.width)
    title.new_column.add_row(board.id, align: 'center')

    out = [ title.to_s(separator: false) ]
    out << header.separator('first') << header
    out << body.separator('middle') << body << body.separator('last')

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts out.join("\n")
  end
end
