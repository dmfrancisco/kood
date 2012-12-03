module Kood
  class User
    include Toy::Store

    # Instead of saving all boards in one repo/branch, each one can live in is own repo
    # The 'boards' branch tracks which branches are boards and where their data is stored
    adapter :git, Kood.repo, branch: 'user'

    # Associations
    list :boards, Kood::Board

    def self.current # For now, there is just one user (TODO: Use the git user.email conf)
      @_user ||= get_or_create("user") # FIXME This breaks without memoization
      @_user.boards.compact! # FIXME The boards collection contains nil values
      @_user
    end
  end
end
