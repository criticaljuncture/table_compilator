module TableCompilator
  class HeaderRow
    include TableCompilator::Row

    def self.generate(options)
      table = options.fetch(:table)
      node = options.fetch(:node)

      cell_nodes = node.xpath("CHED")
      if cell_nodes.empty? || ((table.mode != :ecfr_bulkdata) && cell_nodes.all? do |x|
                                 x.inner_text.try(:strip).blank?
                               end)
        return []
      end

      cells = cell_nodes.map do |cell_node|
        TableCompilator::HeaderCell.new(
          table: table,
          node: cell_node
        )
      end

      max_level = cells.map(&:level).max

      cells.each_with_index do |current_cell, i|
        current_cell.max_level = max_level
        current_cell.descendants = cells
          .slice(i + 1, cells.size)
          .take_while { |x| x.level > current_cell.level }
      end

      cells.group_by(&:level).sort_by(&:first).map do |_level, cells|
        new(
          table: table,
          cells: cells
        )
      end
    end

    attr_reader :table

    delegate :h, :mode, :element_name, to: :table

    def initialize(options)
      @table = options.fetch(:table)
      @cells = options.fetch(:cells)

      @cells.each do |cell|
        cell.row = self
      end
    end

    def all_cells
      @cells
    end

    def cells
      if table.mode == :ecfr_bulkdata
        @cells
      else
        @cells.reject { |x| x.start_column_index + 1 > table.num_columns }
      end
    end

    def to_html
      h.content_tag(element_name(:tr)) do
        html = "".html_safe
        cells.each_with_index do |cell, index|
          html << cell.to_html
        end
        html
      end
    end

    def index
      table.header_rows.index(self)
    end

    def first?
      index.zero?
    end

    def last?
      index + 1 == table.header_rows.size
    end
  end
end
