module Kood
  module Plugin
    class Example < Thor
      desc "foo", "An example command"
      def foo
        puts "Hello from example"
      end
    end
  end
end
