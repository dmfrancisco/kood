require 'active_support/core_ext'
require 'toystore'

module Kood
  class Card
    include Toy::Store

    # Attributes
    attribute :title,        String
    attribute :content,      String
    attribute :participants, Array
    attribute :labels,       Array
    attribute :position,     Integer
    attribute :date,         Time, default: lambda { Time.now }
    attribute :more,         Hash # to store additional user-defined properties

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
      results = options[:exact] ? cards : cards.select { |c| c.title.match /#{ title }/i }

      # If :exact is true and/or there are exact matches, return the first
      results.select { |c| c.title.casecmp(title).zero? }.first || results.first
    end

    def self.get_by_id_or_title(id_or_title, options = {})
      get_by_id(id_or_title, options) || get_by_title(id_or_title, options)
    end

    def self.get_by_id_or_title!(id_or_title, options = {})
      card = get_by_id_or_title(id_or_title, options)
      card || raise("The specified card does not exist.")
    end

    def has_custom_attrs?
      not self.more.blank?
    end

    def printable_attrs(to_print = [ 'labels', 'participants', 'more' ])
      attrs = self.attributes.dup
      attrs.delete_if { |k, v| v.blank? or k.eql? 'more' or not to_print.include? k }
      attrs.merge! self.more

      max_attr_size = attrs.keys.max_by { |k| k.size }.size unless attrs.empty?

      attrs.map do |key, value|
        case value
        when Hash
          value.map { |k, v| "#{ (k.humanize + ":").ljust(max_attr_size + 2) } #{ v }" }
        when Array
          "#{ (key.humanize + ":").ljust(max_attr_size + 2) } #{ value.join(', ') }"
        else
          "#{ (key.humanize + ":").ljust(max_attr_size + 2) } #{ value }"
        end
      end.compact.join("\n")
    end

    def edit_file
      board = Board.current!
      changed = false

      adapter.client.with_stash do
        adapter.client.with_branch({}, board.id) do
          Dir.chdir(board.root) do
            yield filepath if block_given?
          end

          data = File.read(File.join(board.root, filepath))
          self.attributes = Card.adapter.decode(data)
          changed = self.changed?

          save! if changed
          adapter.client.git.reset(hard: true)
        end
      end
      changed
    end

    private

    # ToyStore supports adapters per model but this program needs an adapter per instance
    def self.with_adapter(branch, root)
      current_client = adapter.client
      current_options = adapter.options

      adapter :git, Kood.repo(root), branch: branch, path: 'cards'
      adapter.file_extension = 'md'
      yield
    ensure
      adapter :git, current_client, current_options
      adapter.file_extension = 'md'
    end

    def filepath
      File.join('cards', id) + ".#{ adapter.file_extension }"
    end
  end
end
