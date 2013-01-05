class Kood::CLI < Thor

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
        list_existing_lists(current_board)

      # If the <list-id> argument is present without options, a new list will be created
      elsif no_method_options?
        create_list(current_board, list_id)

      # Since <list-id> is present, operate on the specified list
      else
        operate_on_list(current_board, list_id)
      end
    end
  end
  map 'lists' => 'list'

  private

  def operate_on_list(current_board, list_id)
    list = Kood::List.get!(list_id)

    if options.copy.present?
      # TODO
    end # The copied list may be deleted or moved now

    if options.move.present?
      # TODO
      # If the list was moved, it cannot be deleted

    elsif options.key? 'delete'
      delete_list(current_board, list_id)
    end
  end

  def list_existing_lists(current_board)
    error "No lists were found." if current_board.lists.empty?
    puts current_board.list_ids
  end

  def create_list(current_board, list_id)
    list = current_board.lists.create(id: list_id)

    if list.persisted?
      ok "List created."
    else
      msgs = list.errors.full_messages.join("\n")
      error "#{ msgs }."
    end
  end

  def delete_list(current_board, list_id)
    current_board.lists.destroy(list_id)
    ok "List deleted."
  end
end
