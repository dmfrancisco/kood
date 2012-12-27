class Kood::CLI < Thor

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

      # Since <card-title> is present, operate on the specified card
      else
        operate_on_card(current_board, card_id)
      end
    end
  end
  map 'cards' => 'card'

  private

  def create_card(card_title)
    list = Kood::List.get! options['list']
    list.cards.create(title: card_title)
    ok "Card created."
  end

  def delete_card(current_board, card_id, card_title)
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

  def set_card_attributes(card)
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

  def operate_on_card(current_board, card_id_or_title)
    card_title = card_id = card_id_or_title

    # If <card-title> and the `list` option are specified, a new card is created
    if card_title and options.key? 'list'
      create_card(card_title)
    end

    if options.key? 'copy'
      # TODO
    end # The copied card may be deleted or moved now

    if options.key? 'move'
      # TODO If the card was moved, it cannot be deleted

    elsif options.key? 'delete'
      delete_card(current_board, card_id, card_title)
    end

    if options.key? 'edit'
      edit(card_id_or_title) # Execute the `edit` task
      return # The editor was openned - the following actions should not be triggered
    end

    if options.keys.any? { |option| ['set', 'unset', 'add', 'remove'].include? option }
      card = Kood::Card.get_by_id_or_title!(card_id_or_title)

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
end
