module TableCompilator
  module Row
    attr_reader :cells, :faux_cells, :node

    def defined_columns_match_table?
      @faux_cells ||= 0

      if (defined_columns = table.defined_columns)
        defined_columns == end_column_index + 1 - @faux_cells
      else
        table.num_columns == num_columns
      end
    end

    def end_column_index
      cells.last&.end_column_index
    end

    def includes_spans?
      !!cells.detect { |c| c.colspan > 1 }
    end

    def num_columns
      cells.count
    end
  end
end
