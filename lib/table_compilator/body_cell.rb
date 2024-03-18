module TableCompilator
  class BodyCell
    extend Memoist
    include TableCompilator::Cell

    # key is the ENT I attribute value
    # the first value is how much to ident
    # the second value is whether it should be a hanging indent
    INDENTATION_RULES = {
      1 => [0, true],
      2 => [1, true],
      3 => [2, true],
      4 => [3, true],
      5 => [4, true],
      6 => [5, true],
      7 => [6, true],
      8 => [7, true],
      9 => [8, true],
      10 => [9, true],
      11 => [0, true],
      12 => [1, true],
      13 => [2, true],
      14 => [3, true],
      15 => [4, true],
      16 => [5, true],
      17 => [6, true],
      18 => [7, true],
      19 => [8, true],
      20 => [9, true],
      22 => [0, true],
      24 => [1, false],
      25 => [0, false],
      26 => [0, true],
      27 => [0, false],
      29 => [1, false],
      31 => [0, true],
      38 => [0, true],
      50 => [0, false]
    }.freeze
    attr_reader :row, :node, :index

    delegate :expanded_stub_width, :table, to: :row

    def initialize(options)
      @faux = options[:faux]
      @index = options.fetch(:index)
      @kind = :body
      @node = options.fetch(:node)
      @row = options.fetch(:row)
      @start_column_index = options[:start_column_index] || nil
      @suffix = nil
    end

    def element
      :td
    end

    def css_classes
      super + stub_classes
    end

    def stub_classes
      if stub? || override_indentation
        if primary_indentation&.positive?
          if hanging_indentation
            ["primary-indent-hanging-#{primary_indentation}"]
          else
            ["primary-indent-#{primary_indentation}"]
          end
        else
          []
        end
      else
        []
      end
    end

    def colspan
      if node.attr("A")
        1 + node.attr("A").sub(/^[LRJ]/, "").to_i
      elsif stub? && expanded_stub_width.positive?
        if mode == :ecfr_bulkdata
          if %w[01 02 03 04 05 06 11 12 13 14 15 21].include?(node.attr("I")) || (last_row_in_table? && (row.cells.last == self)) || table.node.attr("OPTS").include?("/") # "/" breaks prior handling?
            1 + expanded_stub_width
          elsif first_cell_in_row? && (row.node.attr("EXPSTB") == "01")
            2
          else
            table.defined_columns - (row.cells.count - 1)
          end
        else
          1 + expanded_stub_width
        end
      elsif node.attr("I") == "28" # "centerhead accross entire table"
        table.num_columns
      elsif node.attr("I") == "22" && table.node.attr("CDEF") == "s50,xls50" # 12v3
        2
      elsif row.node.attr("EXPSTB") == "0s1"
        2
      else
        1
      end
    end
    memoize :colspan

    def rowspan
      1
    end

    def border_top
    end

    def border_bottom
      if table.rules.include?(:horizonal) && row.last?
        :single
      else
        row.border_bottom_for_index(start_column_index)
      end
    end

    def border_left
      return unless start_column.first?

      table.rules.include?(:side) ? :single : nil
    end

    def border_right
      if end_column.border_right
        end_column.border_right
      elsif last_cell_in_row?
        table.rules.include?(:side) ? :single : nil
      else
        table.rules.include?(:down) ? :single : nil
      end
    end

    def primary_indentation
      return override_indentation if override_indentation

      cell_i = node.attr("I").to_i
      INDENTATION_RULES[cell_i].try(:first)
    end

    OVERRIDE_INDENTATION = /i(?<indentation>\d+)/

    def override_indentation
      return unless (match = OVERRIDE_INDENTATION.match(node.attr("O")))

      match[:indentation].to_i
    end
    memoize :override_indentation

    def hanging_indentation
      cell_i = node.attr("I").to_i
      INDENTATION_RULES[cell_i].try(:last)
    end

    def stub?
      # ask the column if it is a stub?
      index.zero?
    end
  end
end
