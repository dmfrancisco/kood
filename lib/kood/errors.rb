module Kood
  class Error < StandardError; end

  class NotFound < Error; end
  class NotUnique < Error; end
  class MultipleDocumentsFound < Error; end
end
