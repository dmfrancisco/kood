class Kood::CLI < Thor

  desc "card [OPTIONS] [<CARD-ID|CARD-TITLE>]", "Display and manage cards"
  #
  # Delete a card. If <card-title> is present, the specified card will be deleted.
  method_option :delete, :aliases => '-d', :type => :boolean
  #
  # Copy a card. <card-title> will be copied to a new card in the given list.
  # <card-title> will be kept intact and a new one is created with the exact same data.
  method_option :copy, :aliases => '-c', :type => :string
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

      # If no arguments and options are specified, display all existing cards
      if card_title.nil? and no_method_options?
        return error "No lists were found." if current_board.lists.empty?
        print_board(current_board)

      # If <card-title> is present without options, display the card with given ID or title
      elsif card_id_or_title and no_method_options?
        card = Kood::Card.find_by_partial_id_or_title!(card_id_or_title)
        print_card(current_board, card)

      else # If <card-title> and the `list` option are present, a new card is created
        create_card(card_id_or_title) if card_id_or_title and options.list.present?

        # Since <card-title> is present, operate on the specified card
        operate_on_card(current_board, card_id)
      end
    end
  end
  map 'cards' => 'card'

  private

  def operate_on_card(current_board, card_id_or_title)
    card_title = card_id = card_id_or_title
    card = Kood::Card.find_by_partial_id_or_title!(card_id_or_title)


    if options.key? 'copy'
      # TODO
    end # The copied card may be deleted or moved now

    if options.key? 'move'
      # TODO If the card was moved, it cannot be deleted

    elsif options.key? 'delete'
      delete_card(card_id)
    end

    if options.key? 'edit'
      edit(card_id_or_title) # Execute the `edit` task
      return # The editor was opened - the following actions should not be triggered
    end

    if options.keys.any? { |option| ['set', 'unset', 'add', 'remove'].include? option }
      if options.key? 'set'
        set_card_attributes(card)
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

  def create_card(card_title)
    list = Kood::List.get! options.list
    list.cards.create(title: card_title, list: list)
    ok "Card created."
  end

  def delete_card(card_id_or_title)
    list = Kood::Card.find_by_partial_id_or_title!(card_id_or_title, unique: true).list
    list.cards.destroy(card_id_or_title)
    ok "Card deleted."
  end

  def set_card_attributes(card)
    options.set.each do |key, value|
      value = Kood::Shell.try_convert(value) # Convert to float or int if possible

      if card.attributes.keys.include? key
        card.send("#{ key }=", value)
      else
        card.more ||= {}
        card.more = card.more.merge({ key => value })
      end
    end
  end

  def print_card(board, card)
    # The board's table may not use all terminal's horizontal space. In order to keep
    # things visually similar / aligned, the card table should have the same width.
    width = Kood::Table.new(board.list_ids.size).width

    table = Kood::Table.new(1, width)
    col = table.new_column
    col.add_row(card.title, separator: (!card.content.empty? or card.has_custom_attrs?))
    col.add_row(card.content) unless card.content.empty?
    col.add_row(card.pretty_attributes) if card.has_custom_attrs?

    opts = options.key?('no-color') ? {} : { color: [:black, :bold] }
    col.add_row("#{ card.id } (created at #{ card.date })", opts)

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts [table.separator('first'), table, table.separator('last')].join("\n")
  end
end
