module Kood
  class Board
    include Toy::Store

    # Instead of saving all boards in one repo/branch, each one can live in is own repo
    adapter :git, Kood.repo, branch: Kood.current_branch

    # Attributes
    # attribute :custom_root, String # TODO Store data (lists & cards) in external repos

    # Associations
    list :lists, Kood::List

    # Observers
    before_create :is_unique_id?
    before_create { |b| Board.update_adapter(b.id) }

    def self.get(id)
      update_adapter(id)
      super
    end

    def self.get!(id)
      super rescue raise "The specified board does not exist."
    end

    # Get the currently checked out board
    def self.current
      get(Kood.current_branch)
    end

    def self.current!
      current or raise("No board has been checked out yet.")
    end

    def is_current?
      Board.current.eql? self
    end

    def delete
      `cd #{ Kood.root } && git reset --hard && git checkout master -q` if is_current?
      `cd #{ Kood.root } && git branch -D #{ id }`
      # Since we delete the branch, the default behavior is not necessary
    end

    def checkout
      branch_is_board = Kood::User.current.boards.any? { |b| b.id == Kood.current_branch }
      `cd #{ Kood.root } && git reset --hard` if branch_is_board
      `cd #{ Kood.root } && git checkout #{ id } -q`
    end

    private

    def is_unique_id?
      raise "A board with this ID already exists." unless Board.get(id).nil?
    end

    def self.update_adapter(id)
      adapter :git, Kood.repo, branch: id # The new board is saved in a new branch
      Kood::List.adapter :git, Kood.repo, branch: id
    end
  end
end
