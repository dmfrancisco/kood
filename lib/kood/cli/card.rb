require 'active_support/core_ext/hash/except'

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

  def operate_on_card(current_board, card_id_or_title, card_id = card_id_or_title)
    card = Kood::Card.find_by_partial_id_or_title!(card_id_or_title)

    copy_card(card)       if options.copy.present?
    delete_card(card_id)  if options.key? 'delete'
    return edit(card_id)  if options.edit.present? # Execute the `edit` task

    if options.any? { |k,v| %w{ set unset add remove }.include? k }
      set_card_attributes(card)    if options.set.present?
      unset_card_attributes(card)  if options.unset.present?
      insert_into_card_array_attribute(current_board, card)  if options.add.present?
      remove_from_card_array_attribute(current_board, card)  if options.remove.present?

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

  def copy_card(card) # TODO Support card copy between boards
    list = options.copy.eql?('copy') ? card.list : Kood::List.get!(options.copy)
    list.cards.create(card.dup.attributes.except 'date', list: list)
    ok "Card copied."
  end

  def delete_card(card_id_or_title)
    list = Kood::Card.find_by_partial_id_or_title!(card_id_or_title, unique: true).list
    list.cards.destroy(card_id_or_title)
    ok "Card deleted."
  end

  # Iterates over all pairs of `options.set` and:
  # - If a key is an attribute of card, sets its value
  # - If a key is not an attribute of card, set it in the `more` hash, which is used to
  #   store custom attributes defined by the user
  #
  # Example: kood card lorem --set title:lorem description:"lorem ipsum" foo:bar
  #
  def set_card_attributes(card)
    options.set.each do |key, value|
      value = Kood::Shell.type_cast(value) # Convert to float or int if possible

      if Kood::Card.attribute? key and not %w{ list list_id more }.include? key.to_s
        card[key] = value
      else
        card.more ||= {}
        card.more = card.more.merge(key => value) # Has to be "card.more=" to be consi-
      end                                         # dered changed (merge! wouldn't work)
    end
  end

  # It operates in the same way of the `set_card_attributes` method but iterates over
  # the `options.unset` array, instead of an hash
  #
  # Example: kood card lorem --unset title description labels
  #
  def unset_card_attributes(card)
    options.unset.each do |key|
      if Kood::Card.attribute? key and not %w{ title list list_id more }.include? key
        card[key] = nil
      else
        card.more ||= {}
        card.more = card.more.except(key) # Has to be "card.more=" to be considered changed
      end
    end
  end

  def update_card_array_attribute(current_board, card, opt)
    values = opt.eql?(:+) ? options.add : options.remove
    key = values.shift

    if key.eql? 'participants'
      board_members = values.map do |v|
        current_board.find_potential_member_by_partial_name_or_email(v) || v
      end
      # Since this command may be called by other users with distinct boards, the found
      # board members may be different, so always keep the typed values if this is about
      # removing participants
      values = opt.eql?(:+) ? board_members : (values + board_members)
    end

    if Kood::Card.attribute? key and Kood::Card.attributes[key].type.eql? Array
      card[key] ||= []
      card[key] = opt.eql?(:+) ? (card[key] + values) : (card[key] - values)
    else
      begin
        card.more ||= {}
        card.more[key] ||= []
        new_value = opt.eql?(:+) ? (card.more[key] + values) : (card.more[key] - values)
        card.more = card.more.merge(key => new_value) # Has to be "card.more=" to be consi-
      rescue TypeError, NoMethodError                 # dered changed (merge! wouldn't work)
        raise Kood::TypeError, "Can't convert the attribute into a list."
      end
    end
  end

  # TODO Example: kood card lorem --add participants David Diogo -a labels bug
  def insert_into_card_array_attribute(current_board, card)
    update_card_array_attribute(current_board, card, :+)
  end

  # TODO Example: kood card lorem --remove participants David
  def remove_from_card_array_attribute(current_board, card)
    update_card_array_attribute(current_board, card, :-)
  end

  def print_card(board, card)
    # The board's table may not use all terminal's horizontal space. In order to keep
    # things visually similar / aligned, the card table should have the same width.
    width = Kood::Table.new(board.list_ids.size).width

    table = Kood::Table.new(1, width)
    col = table.new_column
    attribute_list = card.pretty_attributes
    col.add_row(card.title, separator: !(card.content.empty? and attribute_list.empty?))
    col.add_row(card.content) unless card.content.empty?
    col.add_row(attribute_list) unless attribute_list.empty?

    opts = options.color? ? { color: [:black, :bold] } : {}
    col.add_row("#{ card.id } (created at #{ card.date })", opts)

    # `join` is used to prevent partial content from being printed if an exception occurs
    puts [table.separator('first'), table, table.separator('last')].join("\n")
  end
end
