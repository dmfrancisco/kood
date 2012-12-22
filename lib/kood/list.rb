require 'toystore'

module Kood
  class List
    include Toy::Store

    # Associations
    list :cards, Card

    # Observers
    before_create :id_is_unique?

    def self.get!(id)
      super rescue raise "The specified list does not exist."
    end

    private

    # ToyStore supports adapters per model but this program needs an adapter per instance
    def self.with_adapter(branch, root)
      current_client = adapter.client
      current_options = adapter.options

      adapter :git, Kood.repo(root), branch: branch, path: 'lists'
      Card.with_adapter(branch, root) do
        yield
      end
    ensure
      adapter :git, current_client, current_options
    end

    def id_is_unique?
      raise "A list with this ID already exists." unless List.get(id).nil?
    end
  end
end
