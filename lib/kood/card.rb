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

    def self.get_by_id(id, options = {})
      card = get(id) # FIXME This is not scoped by list
      return card if card

      unless options[:exact]
        cards = options.key?(:list) ? options[:list].cards : Board.current!.cards
        cards = cards.select { |c| c.id.include? id }
        return cards.first unless cards.empty?
      end
    end

    def self.get_by_title(title, options = {})
      cards = options.key?(:list) ? options[:list].cards : Board.current!.cards

      # Get list of partial matches, if the :exact option is set to false
      results = options[:exact] ? cards : cards.select { |c| c.title.match title }

      # If :exact is true and/or there are exact matches, return the first
      results.select { |c| c.title == title }.first || results.first
    end

    def self.get_by_id_or_title(id_or_title, options = {})
      get_by_id(id_or_title, options) || get_by_title(id_or_title, options)
    end

    def self.get_by_id_or_title!(id_or_title, options = {})
      card = get_by_id_or_title(id_or_title, options)
      card || raise("The specified card does not exist.")
    end

    def self.adapter!(branch, root)
      adapter :git, Kood.repo(root), branch: branch, path: 'cards'
      adapter.file_extension = 'md'
    end

    def edit_file(board)
      Dir.chdir(board.root) do
        current_branch = Kood::Git.current_branch
        Kood::Git.checkout(board.id)

        yield filepath if block_given?

        data = File.read(File.join(board.root, filepath))
        self.attributes = Card.adapter.decode(data)
        changed = !changes.empty?
        save! if changed

        Kood::Git.checkout(current_branch, force: true)
        return changed
      end
    end

    private

    def filepath
      File.join('cards', id) + ".#{ adapter.file_extension }"
    end
  end
end
