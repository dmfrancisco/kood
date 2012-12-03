module Kood
  class Card
    include Toy::Store

    # adapter :git, Kood.repo(Board.current.repo_path), branch: Board.current, path: 'cards'

    # Attributes
    attribute :title,       String
    attribute :description, String
    attribute :type,        String, :default => 'feature'
    attribute :owner_email, String
    attribute :status,      String, :default => 'pending'
    attribute :created_at,  Time,   :default => lambda { Time.now }
    attribute :position,    Float
  end
end
