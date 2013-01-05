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
          sliced_rows += self.slice_row(row, options)
        end
        sliced_rows << self.separator if options[:separator]
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

    protected

    def slice_row(row, options = {})
      sliced_rows = []
      i = 0

      while slice = row[i, @width]
        break if slice.blank?
        i += @width

        # This slice may start with space(s). If it does, remove them, grab some extra
        # characters and add them to the slice
        i, slice = lstrip_row(i, slice, row)

        # If this slice does not end with a space, and the first character of the next
        # slice is not a space, it means we would be cutting a word in half. If this
        # is not a big word move it to the next line
        i, slice = hyphenize_row(i, slice, row)

        slice = align_row(slice, options)
        slice = colorize_row(slice, options) if options.key? :color

        sliced_rows << slice
      end
      sliced_rows
    end

    def lstrip_row(i, slice, row)
      slice = slice.lstrip
      len_diff = @width - slice.length
      if slice.length < @width and not row[i, len_diff].blank?
        slice += row[i, len_diff]
        i += len_diff
      end
      return i, slice
    end

    def hyphenize_row(i, slice, row)
      if slice[-1] != ' ' and row[i] and row[i] != ' '
        last_word = slice.split.last
        len_diff = slice.length - last_word.length
        if not last_word.blank? and last_word.length <= (@width * 0.25).floor
          unless slice[0, len_diff].blank?
            slice = slice[0, len_diff]
            i -= last_word.length
          end
        elsif not last_word.blank? # Cut the word and add an hyphen
          slice = slice[0..-2] +"-"
          i -= 1
        end
      end
      return i, slice
    end

    def align_row(slice, options = {})
      slice.send(options[:align], @width)
    end

    def colorize_row(slice, options = {})
      options.key?(:color) ? set_color(slice, *options[:color]) : slice
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
      @cols.map { |col| vbar + " #{ " "*@col_width } " }.join + vbar
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
