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
      row = row.to_s.force_encoding("UTF-8")

      if @width
        sliced_rows = []
        row.split("\n").each do |row|
          sliced = row.scan(/.{1,#{ @width }}/m)
          sliced = [''] if sliced.empty?
          sliced.map! { |s| s.send(options[:align], @width) }
          sliced.map! { |s| s = set_color(s, *options[:color]) } if options.key? :color
          sliced_rows += sliced
        end
        sliced_rows += [self.separator] if options[:separator]
        self.add_rows(sliced_rows)
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

    attr_accessor :width, :cols, :col_width

    def initialize(num_columns, width = nil)
      terminal_width = width || terminal_size[0] || 70
      spare_cols = (terminal_width - 3 * num_columns -1) % num_columns
      @width     = terminal_width - spare_cols
      @num_cols  = num_columns
      @col_width = (@width - 3 * num_columns -1) / num_columns
      @cols      = []
      raise "There is not enough space to accommodate all columns" if @col_width < 5
    end

    def new_column
      raise "Unable to add more columns to table" if @cols.size == @num_cols
      column = Kood::Column.new(@col_width)
      @cols << column
      column
    end

    def to_s(options = { separator: true })
      max_col_rows = biggest_column.rows
      return empty_row(options) if max_col_rows.length.zero?

      output = max_col_rows.each_with_index.map do |col_row, i|
        # Don't print the last separator if this is the last thing to be printed
        row(i, options) unless i == max_col_rows.length-1 and col_row == @cols[0].separator
      end.join.chomp

      improve_cell_corners(output)
    end

    # This code comes from `git.io/command_line_reporter`.
    # A special Thank You to the authors.
    def separator(type = 'middle')
      if unicode?
        case type
        when 'first'  then left, center, right = "\u250F", "\u2533", "\u2513"
        when 'middle' then left, center, right = "\u2523", "\u254A", "\u252B"
        when 'last'   then left, center, right = "\u2517", "\u253B", "\u251B"
        end
      else
        left = right = center = '+'
      end
      left + @cols.map { |c| horizontal_bar * (c.width + 2) }.join(center) + right
    end

    private

    # Returns the column with the largest number of rows
    def biggest_column
      @cols.max_by { |col| col.rows.length }
    end

    # Returns an empty (full width) row
    def empty_row(options = { separator: true })
      vbar = options[:separator] ? self.vertical_bar : " "
      "#{ vbar } #{ ' ' * @col_width } #{ vbar }"
    end

    # Returns an entire row from the table (which may cross several columns)
    def row(row_index, options = { separator: true })
      vbar = options[:separator] ? self.vertical_bar : " "
      out = @cols.map { |col| vbar + " #{ col.rows[row_index] || " "*@col_width } " }.join
      out + vbar + "\n"
    end

    # Improves cell corners  |               |
    # For example,        |--|--| becomes |--+--|
    #                        |               |
    def improve_cell_corners(table_str)
      table_str = table_str.gsub("\u2501 \u2503 \u2501", "\u2501\u2501\u254B\u2501\u2501")
      table_str = table_str.gsub("\u2501 \u2503", "\u2501\u2501\u252B")
      table_str.gsub("\u2503 \u2501", "\u2523\u2501\u2501")
    end
  end
end
