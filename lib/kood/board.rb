module Kood
  class Board
    include Toy::Store

    # Associations
    list :lists, Kood::List

    # Attributes
    attribute :custom_repo, String, virtual: true

    # Observers
    before_create do |board|
      raise "A board with this ID already exists." unless Board.get(board.id).nil?
      Kood.config.custom_repos[board.id] = custom_repo
      Kood.config.save! # Support external branches
      Board.adapter! board.id # To create a board we need to change the checked out branch
    end

    def self.get(id)
      adapter! id
      super
    end

    def self.get!(id)
      super rescue raise "The specified board does not exist."
    end

    def self.current
      get Kood.config.current_board_id
    end

    def self.current!
      current or raise "No board has been checked out yet."
    end

    def is_current?
      Board.current.eql? self
    end

    def delete
      if is_current?
        `cd #{ root } && git reset --hard && git checkout master -q`
        Kood.config.current_board_id = nil
        Kood.config.save!
      end
      `cd #{ root } && git branch -D #{ id }`
      # Since we deleted the branch, the default behavior is not necessary
    end

    def checkout
      Kood.config.current_board_id = id
      Kood.config.save!
    end

    private

    def self.adapter!(board_id)
      board_root = root(board_id)
      adapter :git, Kood.repo(board_root), branch: board_id
      Kood::List.adapter! board_id, board_root
    end

    def root
      Board.root(id)
    end

    def self.root(board_id)
      Kood.config.custom_repos[board_id] or Kood.root
    end
  end
end
