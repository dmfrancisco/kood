module Kood
  # Utility functions related to the Shell.
  #
  # Contains functions for colors from [git.io/thor](//git.io/thor) and for terminal size
  # from [git.io/hirb](//git.io/hirb). A special Thank You for both authors.
  #
  module Shell
    extend self

    # Embed in a String to clear all previous ANSI sequences.
    CLEAR      = "\e[0m"
    # The start of an ANSI bold sequence.
    BOLD       = "\e[1m"

    # Set the terminal's foreground ANSI color to black.
    BLACK      = "\e[30m"
    # Set the terminal's foreground ANSI color to red.
    RED        = "\e[31m"
    # Set the terminal's foreground ANSI color to green.
    GREEN      = "\e[32m"
    # Set the terminal's foreground ANSI color to yellow.
    YELLOW     = "\e[33m"
    # Set the terminal's foreground ANSI color to blue.
    BLUE       = "\e[34m"
    # Set the terminal's foreground ANSI color to magenta.
    MAGENTA    = "\e[35m"
    # Set the terminal's foreground ANSI color to cyan.
    CYAN       = "\e[36m"
    # Set the terminal's foreground ANSI color to white.
    WHITE      = "\e[37m"

    # Set the terminal's background ANSI color to black.
    ON_BLACK   = "\e[40m"
    # Set the terminal's background ANSI color to red.
    ON_RED     = "\e[41m"
    # Set the terminal's background ANSI color to green.
    ON_GREEN   = "\e[42m"
    # Set the terminal's background ANSI color to yellow.
    ON_YELLOW  = "\e[43m"
    # Set the terminal's background ANSI color to blue.
    ON_BLUE    = "\e[44m"
    # Set the terminal's background ANSI color to magenta.
    ON_MAGENTA = "\e[45m"
    # Set the terminal's background ANSI color to cyan.
    ON_CYAN    = "\e[46m"
    # Set the terminal's background ANSI color to white.
    ON_WHITE   = "\e[47m"

    # Set color by using a string or one of the defined constants. If a third
    # option is set to true, it also adds bold to the string. This is based
    # on Highline implementation and it automatically appends CLEAR to the end
    # of the returned String.
    #
    # Pass foreground, background and bold options to this method as
    # symbols.
    #
    # Example:
    #
    #     set_color "Hi!", :red, :on_white, :bold
    #
    def set_color(string, *colors)
      ansi_colors = colors.map { |color| lookup_color(color) }
      "#{ansi_colors.join}#{string}#{CLEAR}"
    end

    # Determines if a shell command exists by searching for it in `ENV['PATH']`.
    # Utility function gently stolen from [git.io/hirb](//git.io/hirb)
    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
    end

    # Returns width and height of terminal when detected, nil if not detected.
    # Utility function gently stolen from [git.io/hirb](//git.io/hirb)
    # @return [Array] width, height
    def terminal_size
      if (ENV['COLUMNS'] =~ /^\d+$/) && (ENV['LINES'] =~ /^\d+$/)
        [ENV['COLUMNS'].to_i, ENV['LINES'].to_i]
      elsif (RUBY_PLATFORM =~ /java/ || (!STDIN.tty? && ENV['TERM'])) && command_exists?('tput')
        [`tput cols`.to_i, `tput lines`.to_i]
      elsif STDIN.tty? && command_exists?('stty')
        `stty size`.scan(/\d+/).map { |s| s.to_i }.reverse
      else
        nil
      end
    rescue
      nil
    end

    # Check if terminal supports unicode characters
    def unicode?
      "\u2501" != 'u2501'
    end

    # Check if terminal supports colors. Condition stolen from Thor.
    def color_support?
      !(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/) || ENV['ANSICON']
    end

    # Horizontal delimiter for box drawing
    # @return [String]
    def horizontal_bar
      unicode? ? "\u2501" : '-'
    end

    # Vertical delimiter for box drawing
    # @return [String]
    def vertical_bar
      unicode? ? "\u2503" : '|'
    end

    # Try to convert a string to a float or integer. Returns the converted object or the
    # original string if it cannot be converted. Based on code from
    # [stackoverflow.com/a/8072164/543293](//stackoverflow.com/a/8072164/543293)
    def type_cast(v)
      ((float = Float(v)) && (float % 1.0 == 0) ? float.to_i : float) rescue v
    end

    protected

    def lookup_color(color)
      self.class.const_get(color.to_s.upcase)
    end
  end
end
