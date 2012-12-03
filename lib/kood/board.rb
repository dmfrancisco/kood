module Kood
  class Board
    include Toy::Store

    # Instead of saving all boards in one repo/branch, each one can live in is own repo
    adapter :git, Kood.repo, branch: Kood.current_branch

    # Attributes
    # attribute :custom_root, String # TODO Store data (lists & cards) in external repos


    # Get the currently checked out board
    def self.current
      get(Kood.current_branch)
    end

    def self.current!
      board = Board.current
      board.nil? ? raise("No board has been checked out yet.") : board
    end

    def self.new(attrs)
      raise "A board with this ID already exists." unless get(attrs[:id]).nil?
      adapter :git, Kood.repo, branch: attrs[:id] # The new board is saved in a new branch
      super
    end

    def self.get(id)
      adapter :git, Kood.repo, branch: id
      super
    end

    def self.get!(id)
      super
    rescue
      raise "The specified board does not exist."
    end

    def delete
      `cd #{ Kood.root } && git checkout master -q` if is_current?
      `cd #{ Kood.root } && git branch -D #{ id }`
      # Since we delete the branch, the default behavior is not necessary
    end

    def checkout
      `cd #{ Kood.root } && git checkout #{ id } -q`
    end

    def is_current?
      Board.current.eql? self
    end
  end
end
