module Kood
  module Core
    extend self

    # Path to the Git repository where all boards and data are saved
    REPO_PATH = File.expand_path("../../../../storage", __FILE__)

    # Get the slug of the currently checked out board
    def current_board
      `cd #{ REPO_PATH } && git rev-parse --abbrev-ref HEAD`.strip
    end

    # Check if an author is member of the currently checked out board
    # Returns true on partial matches and works with both name and email
    def is_member(author)
      !(`cd #{ REPO_PATH } && git log --author "#{ author }" -n 1`).chomp.empty?
    end
  end
end
