require_relative "shell"

module Kood
  class Column < Array
    include Shell

    attr_accessor :width, :rows, :separator

    def initialize(width)
      @width = width
      @rows = []
    end

    def add_row(row, options = {})
      options = { separator: true, align: 'ljust' }.merge(options)

      if @width
        sliced = row.scan(/.{1,#{ @width }}/m).map { |s| s.send(options[:align], @width) }
        sliced = sliced.map { |s| s = set_color(s, options[:color]) } if options.key? :color
        sliced += [self.separator] if options[:separator]
        self.add_rows(sliced)
      else
        @rows.push(row)
      end
    end

    def add_rows(rows)
      @rows.push(*rows)
    end

    def separator
      self.horizontal_bar * @width
    end
  end

  class Table
    include Shell

    attr_accessor :width, :columns

    def initialize(num_columns)
      @width     = terminal_size[0] || 70
      @num_cols  = num_columns
      @col_width = (@width - 3 * num_columns -1) / num_columns
      @columns   = []
    end

    def new_column
      raise "Unable to add more columns to table" if @columns.size == @num_cols
      column = Kood::Column.new(@col_width)
      @columns << column
      column
    end

    def to_s(options = { separator: true })
      max_num_rows = @columns.max_by { |col| col.rows.length }.rows.length
      vertical_bar = options[:separator] ? self.vertical_bar : " "
      output = ""

      max_num_rows.times do |i|
        # Don't print the last separator if this is the last thing to be printed
        break if max_num_rows == i+1 and @columns[0].rows[i] == @columns[0].separator

        columns.each do |col|
          output += vertical_bar + " #{ col.rows[i] || " "*@col_width } "
        end
        output += vertical_bar + "\n"
      end

      # Improve unicode table corners. For example,
      #      |                 |
      #   |--|--|  becomes  |--+--|
      #      |                 |
      output.gsub!("\u2501 \u2503", "\u2501\u2501\u252B")
      output.gsub!("\u2503 \u2501", "\u2523\u2501\u2501")
      output.gsub!("\u2501 \u2503 \u2501", "\u2501\u2501\u254B\u2501\u2501")
      output
    end

    # This code comes from `git.io/command_line_reporter`.
    # A special Thank You to the authors.
    def separator(type = 'middle')
      if unicode?
        case type
        when 'first'
          left   = "\u250F"
          center = "\u2533"
          right  = "\u2513"
        when 'middle'
          left   = "\u2523"
          center = "\u254A"
          right  = "\u252B"
        when 'last'
          left   = "\u2517"
          center = "\u253B"
          right  = "\u251B"
        end
      else
        left = right = center = '+'
      end

      left + self.columns.map { |c| horizontal_bar * (c.width + 2) }.join(center) + right
    end
  end
end
