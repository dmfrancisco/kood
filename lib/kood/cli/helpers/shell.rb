module Kood
  module Shell
    extend self

    # Group of utility functions for colors from git.io/thor
    #
    CLEAR = "\e[0m" # Embed in a String to clear all previous ANSI sequences
    BOLD  = "\e[1m" # The start of an ANSI bold sequence

    # Terminal's foreground ANSI color
    BLACK   = "\e[30m"
    RED     = "\e[31m"
    GREEN   = "\e[32m"
    YELLOW  = "\e[33m"
    BLUE    = "\e[34m"
    MAGENTA = "\e[35m"
    CYAN    = "\e[36m"
    WHITE   = "\e[37m"

    # Terminal's background ANSI color
    ON_BLACK   = "\e[40m"
    ON_RED     = "\e[41m"
    ON_GREEN   = "\e[42m"
    ON_YELLOW  = "\e[43m"
    ON_BLUE    = "\e[44m"
    ON_MAGENTA = "\e[45m"
    ON_CYAN    = "\e[46m"
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
    #   set_color "Hi!", :red, :on_white, :bold
    #
    def set_color(string, *colors)
      ansi_colors = colors.map { |color| lookup_color(color) }
      "#{ansi_colors.join}#{string}#{CLEAR}"
    end

    # Determines if a shell command exists by searching for it in ENV['PATH'].
    # Utility function gently stolen from git.io/hirb
    def command_exists?(command)
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
    end

    # Returns [width, height] of terminal when detected, nil if not detected.
    # Utility function gently stolen from git.io/hirb
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
    def horizontal_bar
      unicode? ? "\u2501" : '-'
    end

    # Vertical delimiter for box drawing
    def vertical_bar
      unicode? ? "\u2503" : '|'
    end

    # Try to convert a string to a float or integer. Returns the converted object or the
    # original string if it cannot be converted (from stackoverflow.com/a/8072164/543293)
    def type_cast(v)
      ((float = Float(v)) && (float % 1.0 == 0) ? float.to_i : float) rescue v
    end

    protected

    def lookup_color(color)
      self.class.const_get(color.to_s.upcase)
    end
  end
end
