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

    def self.adapter!(branch, root)
      adapter :git, Kood.repo(root), branch: branch, path: 'lists'
      Card.adapter! branch, root
    end

    private

    def id_is_unique?
      raise "A list with this ID already exists." unless List.get(id).nil?
    end
  end
end
