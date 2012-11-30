module Kood
  class Board
    attr_reader :slug

    def initialize(slug)
      @slug = slug
    end

    def == (object)
      self.slug == object
    end
    alias eql? ==
  end
end
