class Kood::CLI < Thor

  desc "sync [<BOARD-ID>]", "Synchronize a board" # Only published branches can be synced
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def sync(board_id = nil)
    board = get_board_or_current!(board_id)
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
  end

  desc "pull [<BOARD-ID>]", "Pull changes made to the board from the central server", hide: true
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def pull(board_id = nil)
    board = get_board_or_current!(board_id)
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
  end

  desc "push [<BOARD-ID>]", "Push changes made to the board to the central server", hide: true
  #
  # Specify a custom remote reference. If not present, the default remote used is "origin".
  method_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  def push(board_id = nil)
    board = get_board_or_current!(board_id)
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
  end

end
