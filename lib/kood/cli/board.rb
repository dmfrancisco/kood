class Kood::CLI < Thor

  desc "board [OPTIONS] [<BOARD-ID>]", "Display and manage boards"
  #
  # Delete a board. If <board-id> is present, the specified board will be deleted.
  # With no arguments, the current board will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Copy a board. <board-id> will be copied to <new-board-id>.
  # <board-id> will be kept intact and a new one is created with the exact same data.
  method_option :copy, :aliases => '-c', :type => :string
  #
  # Create a board in an external repository.
  method_option :repo, :aliases => '-r', :type => :string
  def board(board_id = nil)
    # If no arguments and options are present, the command displays all existing boards
    if board_id.nil? and no_method_options?
      list_existing_boards

    # If the <board-id> argument is present without options, a new board will be created
    elsif no_method_options? or options.repo.present?
      create_board(board_id)

    else # Since <board-id> is present, operate on the specified board
      operate_on_board(board_id)
    end
  end
  map 'boards' => 'board'

  private

  def operate_on_board(board_id)
    board = get_board_or_current!(board_id) # Raises exception if inexistent

    copy_board(board)      if options.copy.present?
    delete_board(board_id) if options.key? 'delete'
  end

  def list_existing_boards
    return error "No boards were found." if Kood.config.boards.empty?

    max_board_id = Kood.config.boards.max_by { |b| b.id.size }.id.size
    Kood.config.boards.each do |b|
      marker     = b.is_current? ? "* " : "  "
      visibility = b.published?  ? "shared" : "private"
      repo_path  = b.root.gsub(/^#{ ENV['HOME'] }/, "~") if b.external?
      visibility = "(#{ visibility }#{ ' at '+ repo_path if b.external? })"
      visibility = set_color(visibility, :black, :bold) if options.color?
      puts marker + b.id.to_s.ljust(max_board_id + 2) + visibility
    end
  end

  def create_board(board_id)
    board = Kood.config.boards.create(id: board_id, custom_repo: options['repo'])

    unless board.persisted?
      msgs = board.errors.full_messages.join("\n")
      return error "#{ msgs.gsub('Id', 'Board ID') }."
    end

    if Kood.config.boards.size == 1
      board.select
      ok "Board created and selected."
    else
      ok "Board created."
    end
  end

  def copy_board(board)
  end

  def delete_board(board_id)
    Kood.config.boards.destroy(board_id)
    ok "Board deleted."
  end

  def get_board_or_current!(board_id)
    board_id.nil? ? Kood::Board.current! : Kood::Board.get!(board_id)
  end

  def print_board(board)
    opts = options.color? ? { color: [:black, :bold] } : {}
    num_lists = board.list_ids.size
    header = Kood::Table.new(num_lists)
    body   = Kood::Table.new(num_lists)

    board.lists.each do |list|
      header.new_column.add_row(list.id, align: 'center', separator: false)

      column = body.new_column
      list.cards.each do |card|
        card_info = card.title
        if options.color?
          colored_separator = color_separator_with_labels(column.separator, card.labels)
          column.add_row(colored_separator, slice: false)
        else
          labels = card.labels.uniq.map { |l| "##{ l }" }.join(", ")
          card_info += " #{ labels }" unless labels.blank?
          column.add_row(column.separator, separator: false)
        end
        column.add_row(card_info, separator: false)
        column.add_row(card.id.slice(0, 8), opts.merge(separator: false))
      end
      column.add_row(column.separator, slice: false)
    end

    title = Kood::Table.new(1, body.width)
    title.new_column.add_row(board.id, align: 'center')

    out = [ title.to_s(separator: false) ]
    out << header.separator('first') << header << body << body.separator('last')

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts out.join("\n")
  end

  def color_separator_with_labels(separator, labels)
    return separator if labels.blank? or not options.color?

    hbar = Kood::Shell.horizontal_bar
    colored_bars = labels.map { |l| set_color(hbar * 3, label_to_color(l)) }.uniq

    if colored_bars.length * 3 > separator.length
      colored_bars = colored_bars[0...separator.length/3-1]
      colored_bars << set_color(hbar * 3, :black, :bold)
    end

    separator[0...-colored_bars.length*3] + colored_bars.join
  end

  def label_to_color(label)
    (Kood.config.labels[label] || 'blue').to_sym
  end
end
