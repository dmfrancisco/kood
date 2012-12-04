module Kood
  class Card
    include Toy::Store

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
