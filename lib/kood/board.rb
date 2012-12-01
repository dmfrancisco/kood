module Kood
  class Board
    include Toy::Store

    # The 'boards' branch tracks which branches are boards and where their data is stored
    adapter :git, Kood.repo, branch: 'boards'

    # Attributes
    attribute :repo_path, String

    def self.all
      # Toystore does not provide a method to list objects
      branches = Kood.repo.branches # For now, this assumes board ids == branch names
      branches.map { |b| get(b.name) unless ['master', 'boards'].include? b.name }.compact
    end

    def self.any?
      not all.empty?
    end

    # Get the currently checked out board
    def self.current
      get(`cd #{ Kood.repo_root } && git rev-parse --abbrev-ref HEAD`.chomp)
    end

    def self.current!
      board = Board.current
      raise "No board has been checked out yet." if board.nil?
      board
    end

    def self.new(attrs)
      raise "A board with this ID already exists." unless get(attrs[:id]).nil?
      Adapter[:git].new(Kood.repo, branch: attrs[:id]).write('kood', '')
      super
    end

    def self.get!(attrs)
      super
    rescue
      raise "The specified board does not exist."
    end

    def delete
      Dir.chdir(Kood.repo_root) do
        `git checkout master -q` if is_current?
        `git branch -D #{ id }`
      end
      super
    end

    def checkout
      `cd #{ Kood.repo_root } && git checkout #{ id } -q`
    end

    def is_current?
      Board.current.eql? self
    end
  end
end
