class Kood::CLI < Thor

  private

  # Load third-party commands / plugins
  #
  def self.load_plugins
    program = File.basename $PROGRAM_NAME
    command = ARGV.first

    if program.eql? 'kood' # File is being imported from the bin and not from the test suite
      unless command.nil? or Kood::CLI.method_defined? command # Check if command is unknown
        begin
          plugin_name = command # The command is the name of the plugin

          # Require the plugin, which must be accessible and follow the naming convention
          require "kood-plugin-#{ plugin_name }"

          # Transform plugin name to a valid class name (for example, foo_bar becomes FooBar)
          plugin_class_name = Thor::Util.camel_case(plugin_name)

          # Get the class and register it (the plugin must extend Thor)
          plugin_class = Kood::Plugin.const_get(plugin_class_name)
          Kood::CLI.register(plugin_class, plugin_name, plugin_name, "Kood plugin")
        rescue LoadError
          # TODO Thor supports partial subcommands and aliases for subcommands. The
          # `method_defined?` condition is not enough. For now, we don't exit here and
          # everything should still work as expected, but this could be improved.
          #
          # puts "Could not find command or plugin \"#{ plugin_name }\"."
        end
      end
    end
  end

end
