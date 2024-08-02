module TableCompilator
  class HeaderCell
    include TableCompilator::Cell

    attr_reader :table, :node, :descendants
    attr_accessor :row, :max_level, :parent, :children

    delegate :mode, :element_name, to: :table

    def initialize(options)
      @kind = :header
      @node = options.fetch(:node)
      @suffix = nil
      @table = options.fetch(:table)
    end

    def element
      :th
    end

    def alignment
      if mode == :ecfr_bulkdata
        super
      else
        :center
      end
    end

    def body
      if mode == :ecfr_bulkdata
        options = {}
        options["rowspan_present"] = "true" if rowspan > 1 # "5:2.0.1.1.25.3.137.15.7"
        options["colspan_present"] = "true" if colspan > 1
        table.transform(node.to_xml, strip: false, options: options)
      elsif mode == :ecfr
        table.transform(node.to_xml, strip: true)
      else
        table.transform(node.to_xml)
      end
    end

    def border_top
      return unless table.rules.include?(:horizonal) && row.first?

      table.top_border_style
    end

    def border_bottom
      return unless table.rules.include?(:horizonal)

      :single
    end

    def border_left
      return unless first_cell_in_row?

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

    def index
      row.all_cells.index(self)
    end

    def descendants=(descendants)
      @descendants = descendants

      @children = @descendants.select { |x| x.level == @descendants.first.level }
      @children.each { |x| x.parent = self }
    end

    def colspan
      if children.present?
        children.sum(&:colspan)
      else
        1
      end
    end

    def html_attributes
      case mode
      when :ecfr_bulkdata
        {
          class: "gpotbl_colhed"
        }.merge(super.slice(
          :colspan,
          :rowspan
        )).merge({
          scope: "col"
        })
      else
        super
      end
    end

    def rowspan
      row_to_get_to = children.present? ? children.first.level - 1 : max_level
      row_to_get_to - level + 1
    end

    def level
      @node.attr("H").to_i
    end

    def start_column_index
      if parent
        parent.start_column_index +
          previous_siblings.sum(&:colspan)
      elsif previous_cell_in_row.nil?
        0
      else
        previous_cell_in_row.end_column_index + 1
      end
    end

    def first_cell_in_row?
      start_column_index.zero?
    end

    def previous_siblings
      parent.children.take_while { |x| x != self }
    end
  end
end
