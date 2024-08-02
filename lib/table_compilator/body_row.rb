module TableCompilator
  class BodyRow
    include TableCompilator::Row

    attr_reader :table

    delegate :h, :mode, :element_name, to: :table

    def initialize(options)
      @table = options.fetch(:table)
      @node = options.fetch(:node)
    end

    def to_html
      return unless cells.present?

      result = "".html_safe
      result << "\n" if mode != :ecfr_bulkdata

      result << h.safe_join([
        page_break_row,
        h.content_tag(element_name(:tr)) do
          cells.each_with_index do |cell, index|
            html = cell.to_html
            h.concat "\n" if mode != :ecfr_bulkdata
            h.concat html
          end
          h.concat "\n" if mode != :ecfr_bulkdata
        end
      ])

      if mode == :ecfr_bulkdata
        result = result.gsub("&#9166;&#9251;&#9166;", "&#9166;&#9166;&#9251;&#9166;").html_safe # 13v1
      end

      result
    end

    def page_break_row
      return unless page_break_node

      h.content_tag(element_name(:tr), class: "page_break") do
        h.content_tag(element_name(:td), colspan: table.num_columns) do
          table.transform(page_break_node.to_xml)
        end
      end
    end

    def page_break_node
      node.xpath("PRTPAGE").first
    end

    def cells
      return @cells if @cells

      @cells = []
      node.xpath("ENT").each_with_index do |node, i|
        cell = TableCompilator::BodyCell.new(
          row: self,
          node: node,
          index: i
        )
        @cells << cell
      end

      set_column_indices(@cells)
      @cells = append_missing_cells(@cells)

      @cells = @cells.select(&:start_column) unless mode == :ecfr_bulkdata
      @cells
    end

    def set_column_indices(cells, start_column_index: 0)
      cells.each do |cell|
        cell.start_column_index = start_column_index
        start_column_index += cell.colspan
      end
      cells
    end

    def all_cells
      @cells
    end

    def expanded_stub_width
      @expanded_stub_width ||= node.attr("EXPSTB").try(:to_i) ||
        prior_row.try(:expanded_stub_width) ||
        0
    end

    CODE_VALUES = {"n" => nil, "s" => :single, "d" => :double, "b" => :bold}.freeze

    def border_bottom_for_index(i)
      codes = (node.attr("RUL") || "").split(",")

      if /\u{E199}/.match?(codes.last)
        val = codes.last.sub!(/\u{E199}/, "")
        codes.fill(val, codes.size, table.num_columns - 1)
      end

      code = codes[i]
      code ||= codes[0] # ?! 49_571.108_S14.9.3.12.6.3
      CODE_VALUES[code]
    end

    def next_row
      table.body_rows[index + 1]
    end

    def prior_row
      table.body_rows[index - 1] if index.positive?
    end

    def index
      @index ||= table.body_rows.index(self)
    end

    def first?
      index.zero?
    end

    def last?
      index + 1 == table.body_rows.size
    end

    def second_to_last?
      index + 2 == table.body_rows.size
    end

    def append_missing_cells(cells)
      return [] if cells.empty? || @faux_cells

      @faux_cells = 0
      missing_cells = []
      start_column_index = if (last = cells.last)
        last.end_column_index + 1
      else
        0
      end
      (cells.sum(&:colspan)...table.num_columns).each do |i|
        @faux_cells += 1

        cell = TableCompilator::BodyCell.new(
          faux: true,
          row: self,
          node: TableCompilator::StubNode.new,
          index: i
        )

        missing_cells << cell
        cells << cell
      end

      set_column_indices(missing_cells, start_column_index: start_column_index)

      cells
    end
  end
end
