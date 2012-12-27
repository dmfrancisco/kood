class Kood::CLI < Thor

  desc "switch <BOARD-ID>", "Switches to the specified board"
  def switch(board_id)
    Kood::Board.get!(board_id).select
    ok "Board switched to #{ board_id }."
  end
  map 'select' => 'switch'

end
