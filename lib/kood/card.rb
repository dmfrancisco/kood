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

    def self.get_by_title!(title, options)
      # Only search for a card in the given board
      raise("The specified card does not exist.") unless options.key? :board

      cards = if options.key? :list # Search in a given list
        options[:list].cards
      else # Search in all lists
        options[:board].lists.inject([]) { |cards, list| cards += list.cards }
      end

      # Get list of partial matches, if the :exact option is set to false
      results = options[:exact] ? cards : cards.select { |c| c.title.match title }

      # If :exact is true and/or there are exact matches, return the first
      results = results.select { |c| c.title == title }.first || results.first
      results || raise("The specified card does not exist.")
    end

    def self.adapter!(branch, root)
      adapter :git, Kood.repo(root), branch: branch, path: 'cards'
    end

    def filepath
      File.join('cards', id)
    end
  end
end
