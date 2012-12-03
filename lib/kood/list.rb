module Kood
  class List
    include Toy::Store

    adapter :git, Kood.repo, branch: Kood.current_branch, path: 'lists'

    # Associations
    list :cards, Card

    # Observers
    before_create :is_unique_id?

    def self.get!(id)
      super rescue raise "The specified list does not exist."
    end

    private

    def is_unique_id?
      raise "A list with this ID already exists." unless List.get(id).nil?
    end
  end
end
