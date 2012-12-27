class Kood::CLI < Thor

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
  end

end
