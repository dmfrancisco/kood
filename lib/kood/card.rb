require 'active_support/core_ext'
require 'toystore'

module Kood
  class Card
    include Toy::Store

    # References
    reference :list, List

    # Attributes
    attribute :title,        String
    attribute :content,      String
    attribute :participants, Array
    attribute :labels,       Array
    attribute :position,     Integer
    attribute :date,         Time, default: lambda { Time.now }
    attribute :more,         Hash # to store additional user-defined properties

    def self.get!(id)
      super rescue raise NotFound, "The specified card does not exist."
    end

    def self.find_all_by_partial_attribute(attrs, search_param, options = {})
      cards = options.key?(:list) ? options[:list].cards : Board.current!.cards

      attrs.split('_or_').map do |a|
        cards.select { |c| c.attributes[a].match /#{ search_param }/i }
      end.flatten
    end

    # If the `unique` option is present, an exception must be raised if:
    # - More than one exact match was found
    # - Zero exact matches were found but more than one partial match was found
    # If `unique` not present, return the first match giving preference to exact matches
    #
    def self.find_by_partial_attribute!(attrs, search_param, options = {})
      must_unique = options[:unique] == true

      # Find partial (and exact) matches
      matches = find_all_by_partial_attribute(attrs, search_param, options)

      # If nothing was found, raise an exception
      raise NotFound, "The specified card does not exist." if matches.empty?

      # Refine the search and retrieve only exact matches
      exact_matches = attrs.split('_or_').map do |a|
        matches.select { |c| c.attributes[a].casecmp(search_param).zero? }
      end.flatten

      if (must_unique and exact_matches.length == 1) or (!must_unique and !exact_matches.empty?)
        exact_matches.first
      elsif matches.length > 1 and must_unique
        raise MultipleDocumentsFound, "Multiple cards match the given criteria."
      else
        matches.first
      end
    end

    # FIXME With humanize "foo_id" becomes "Foo" instead of "Foo Id" which may be confusing
    def pretty_attributes(to_print = [ 'labels', 'participants', 'more' ])
      attrs = self.attributes.dup
      attrs.delete_if { |k, v| v.blank? or k.eql? 'more' or not to_print.include? k }
      attrs.merge! self.more
      max_size = attrs.keys.max_by { |k| k.humanize.size }.humanize.size unless attrs.empty?

      attrs.map do |key, value|
        case value
        when Array
          "#{ (key.humanize + ":").ljust(max_size + 2) } #{ value.join(', ') }"
        else
          "#{ (key.humanize + ":").ljust(max_size + 2) } #{ value }"
        end
      end.compact.join("\n")
    end

    def edit_file
      board = Board.current!
      changed = false

      adapter.client.with_stash_and_branch(board.id) do
        Dir.chdir(board.root) do
          yield filepath if block_given?
        end

        data = File.read(File.join(board.root, filepath))
        self.attributes = Card.adapter.decode(data)
        changed = self.changed?

        save! if changed
        adapter.client.git.reset(hard: true)
      end
      changed
    end

    private

    def self.method_missing(meth, *args, &block)
      if meth.to_s =~ /^find_all_by_partial_(.+)$/
        find_all_by_partial_attribute($1, *args)
      elsif meth.to_s =~ /^find_by_partial_(.+)!$/
        find_by_partial_attribute!($1, *args)
      else
        super
      end
    end

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
