module Kood
  class Card
    include Toy::Store

    # Attributes
    attribute :title,      String
    attribute :content,    String
    attribute :position,   Float
    attribute :created_at, Time, default: lambda { Time.now }

    def self.get!(id)
      super rescue raise "The specified card does not exist."
    end

    def self.get_by_title!(title, options = {})
      cards = if options.key? :list # Search in a given list
        options[:list].cards
      else # Search in all lists
        Board.current!.lists.inject([]) { |cards, list| cards += list.cards }
      end

      # Get list of partial matches, if the :exact option is set to false
      results = options[:exact] ? cards : cards.select { |c| c.title.match title }

      # If :exact is true and/or there are exact matches, return the first
      results = results.select { |c| c.title == title }.first || results.first
      results || raise("The specified card does not exist.")
    end

    def self.get_by_id_or_title!(id_or_title, options = {})
      card = Kood::Card.get(id_or_title)
      card ||= Kood::Card.get_by_title!(id_or_title, options)
    end

    def self.adapter!(branch, root)
      adapter :git, Kood.repo(root), branch: branch, path: 'cards'
    end

    def edit_file(board)
      Dir.chdir(board.root) do
        current_branch = `git rev-parse --abbrev-ref HEAD`.chomp
        `git checkout #{ board.id } -q`

        yield filepath if block_given?

        data = File.read(File.join(board.root, filepath))
        self.attributes = Card.adapter.decode(data)
        changed = !changes.empty?
        save! if changed

        `git reset --hard && git checkout #{ current_branch } -q`
        return changed
      end
    end

    private

    def filepath
      File.join('cards', id)
    end
  end
end
