require "memoist"

module TableCompilator
  module Cell
    extend Memoist

    attr_accessor :suffix, :start_column_index
    attr_reader :kind
    delegate :h, :mode, :element_name, to: :table

    BLANK_PLACEHOLDER_CELL_BODY = " \n "

    def to_html
      result = "".html_safe

      use_content_tag = ((html = body).present? && html.strip.present?) || ((@kind == :header) && Spaces.complex?(html))
      use_content_tag = true if !use_content_tag && node.attributes["I"]&.value == "11" # 7v2
      use_content_tag = true if preceding&.body&.ends_with?(Compatibility::PLACEHOLDER_HTML_EMPTY_MARKER)

      attributes = html_attributes

      if !use_content_tag && (attributes[:style].present? || (!faux? && (
          ((row.cells.count - (row.faux_cells || 0)) == 1) ||
          last_cell_in_row? # 7v11
        )))
        use_content_tag = true
        if html == BLANK_PLACEHOLDER_CELL_BODY && mode == :ecfr_bulkdata
          html = Compatibility::ADJACENT_MARKER # 20v2 (was Compatibility::IRREGULAR_MARKER)
        end
      end

      if html == Compatibility::PLACEHOLDER_HTML_BELOW_PARAGRAPH_MARKER ||
          html == Compatibility::PLACEHOLDER_HTML_IRREGULAR_MARKER ||
          html == Compatibility::PLACEHOLDER_HTML_RETURN
        html = Compatibility::ADJACENT_MARKER
      end

      html << suffix if suffix

      # don't allow an adjacent cell marker alone to create a new line
      html = Compatibility::ADJACENT_MARKER if blank? && !Spaces.any?(html) && html.include?(Compatibility::PLACEHOLDER_HTML_ADJACENT_CELL_MARKER)

      result << if use_content_tag
        h.content_tag(element_name(element), html, attributes)
      else
        h.tag(element_name(element), attributes)
      end

      result
    end

    def body
      result = table.transform(node.to_xml, strip: !(mode == :ecfr_bulkdata))

      if mode == :ecfr_bulkdata
        if !last_cell_in_row? || last_row_in_table? || result.include?(Compatibility::ADJACENT_CELL_MARKER)
          if result.include?("<br/>") # don't trim LI lists
            result.gsub!(/\n+\z/, "")
          else
            result.gsub!(/\s+\z/, "")
          end
        end

        # don't allow markers alone to create a new line between cell open and start of tag enclosed content
        result.gsub!(/\A(?:#{[Compatibility::PLACEHOLDER_HTML_BELOW_OPENING_MARKER, Compatibility::PLACEHOLDER_HTML_BELOW_PARAGRAPH_MARKER, Compatibility::PLACEHOLDER_HTML_IRREGULAR_MARKER, Compatibility::BELOW_OPENING_MARKER, Compatibility::BELOW_PARAGRAPH_MARKER, Compatibility::IRREGULAR_MARKER].join("|")})+</o, "<")

        # don't allow markers alone to create a new line between cell open and start of any content for first cell in row
        result.gsub!(/\A(?:#{[Compatibility::PLACEHOLDER_HTML_BELOW_PARAGRAPH_MARKER, Compatibility::BELOW_PARAGRAPH_MARKER].join("|")})+/, "") if first_cell_in_row?

        following_content_marker = false
        if (following_content = following&.node&.content) && (
          following_content.starts_with?(Compatibility::BELOW_PARAGRAPH_MARKER) ||
          following_content.starts_with?(Compatibility::PLACEHOLDER_HTML_BELOW_PARAGRAPH_MARKER)
        )
          result << "\n"
          following_content_marker = true
        end

        result += " " if result.starts_with?(" - ")
        result += " " if result == "_____" && bottom_right_cell_in_table?
        if result.blank? && result.exclude?(Spaces::EM_SPACE) && result.exclude?(Spaces::EN_SPACE) # 40v7 EN_SPACE
          result = following_content_marker ? Compatibility::EMPTY : BLANK_PLACEHOLDER_CELL_BODY
        end

        if result == Compatibility::PLACEHOLDER_HTML_IRREGULAR_MARKER + Compatibility::PLACEHOLDER_HTML_RETURN
          result = BLANK_PLACEHOLDER_CELL_BODY
        end

        result = result.html_safe # rubocop:disable Rails/OutputSafety
      end

      result
    end
    memoize :body

    def css_classes
      [
        alignment
      ] + border_classes
    end

    def blank?
      @blank ||= !!(
          body.blank? || (
            (mode == :ecfr_bulkdata) &&
            body.gsub(Compatibility::IRREGULAR_MARKER, "")
                .gsub(Compatibility::PLACEHOLDER_HTML_IRREGULAR_MARKER, "")
                .gsub(Compatibility::PLACEHOLDER_HTML_ADJACENT_CELL_MARKER, "")
                .gsub(Compatibility::PLACEHOLDER_HTML_BELOW_OPENING_MARKER, "")
                .blank?
          )
        )
    end
    memoize :blank?

    def html_attributes
      {}.tap do |attributes|
        case mode
        when :ecfr_bulkdata
          attributes[:align] = alignment

          attributes[:class] = "gpotbl_cell"
          attributes[:colspan] = colspan if colspan > 1
          attributes[:rowspan] = rowspan if rowspan > 1
          attributes[:scope] = "row" if index == 0
          case node.attributes["I"]&.value
          when "02", "12"
            attributes[:style] = "padding-left: 2em"
          when "03", "13"
            attributes[:style] = "padding-left: 4em"
          when "04", "14"
            attributes[:style] = "padding-left: 6em"
          when "05", "15"
            attributes[:style] = "padding-left: 8em"
          when "06", "16"
            attributes[:style] = "padding-left: 10em"
          when "07", "17"
            attributes[:style] = "padding-left: 12em"
          when "08", "18"
            attributes[:style] = "padding-left: 14em"
          when "09", "19"
            attributes[:style] = "padding-left: 16em"
          end
        else
          attributes[:colspan] = colspan if colspan > 1
          attributes[:rowspan] = rowspan if rowspan > 1
          attributes[:class] = css_classes.join(" ")
        end
      end
    end

    def alignment
      effective_code = node.attr("I")
      effective_code ||= (mode == :ecfr_bulkdata) ? node.attr("O") : nil

      if !effective_code && (mode == :ecfr_bulkdata) && (first_cell_in_row_i = first_cell_in_row.node.attr("I"))
        case first_cell_in_row_i
        when "21"
          # no-op # 7v2 "7:2.1.1.1.3.3.198.448" 3rd table, first column only centered
        else
          effective_code = first_cell_in_row_i # fallback 49/535.5 Table 14 (row 3)
        end
      end

      effective_alignment_attribute = node.attr("A")

      result = case effective_code
      when "21", "25", "28"
        :center
      end

      if (effective_code == "xl") && ((preceding&.node&.attr("I") == "25") || (preceding&.preceding&.node&.attr("I") == "25")) # 7v4
        result = :center
      end

      result ||= if effective_alignment_attribute
        case effective_alignment_attribute.match(/^(\D)/).try(:[], 1)
        when "1"
          :center
        when "R"
          :right
        when "L"
          :left
        when "J"
          :justify
        when nil
          :center
        end
      elsif mode == :ecfr_bulkdata
        if (table.defined_columns != row.cells.count) && last_cell_in_row? && (!row.index == 0)
          nil
        elsif row.index == 0 && !top_left_cell_in_table?
          if (blank? || body.include?("<br/>")) && (node.attr("O") == "xl") && (preceding_alignment = preceding_non_blank&.alignment) && preceding_alignment == :center
            preceding_alignment
          else
            start_column&.alignment
          end
        else
          wrong_column&.alignment || :none
        end
      else
        start_column&.alignment
      end

      result ||= case effective_code
      when "21", "25", "28"
        :center
      when "22"
        if mode == :ecfr_bulkdata
          :left
        end
      end

      if !result && (mode == :ecfr_bulkdata)
        result ||= :center unless faux? || last_cell_in_row? # 15v2
      end

      if body == Compatibility::PLACEHOLDER_HTML_EM_SPACE
        if row.faux_cells > 0
          if !self.class.name == "HtmlCompilator::Tables::BodyCell"
            result = :right
          end
        end
      end

      if body == BLANK_PLACEHOLDER_CELL_BODY && (mode == :ecfr_bulkdata)
        override = nil

        if !faux?
          preceding_a = preceding_non_blank&.node&.attr("A")
          if preceding_a && /\A(?:L|\d+)/.match?(preceding_a)
            override = :left
          end
        end

        if preceding && !preceding.faux? && (preceding.colspan > 1) # faux cell to the right of content
          if preceding&.first_cell_in_row? && (row.node.attr("EXPSTB") == "01")
            override = preceding.alignment unless result == :right
          elsif preceding&.first_cell_in_row? && (row.node.attr("EXPSTB") == "02") && !last_cell_in_row?
            override = if preceding.colspan > 2
              preceding.end_column.alignment
            else
              preceding.alignment
            end
          else
            override = preceding.end_column.alignment unless result == :right
          end
        elsif faux? && preceding.faux?
          if last_cell_in_row? && preceding_non_faux
            override = :left
            if ((column_alignment = end_column&.alignment) != :left) || (row.includes_spans? && (column_alignment = second_to_last_column&.alignment) == :center)
              if (last_row_in_table? && (row.node&.attr("EXPSTB") == "02")) ||
                  (second_to_last_row_in_table? && (row.node&.attr("EXPSTB") == "02") && (row.next_row&.node&.attr("EXPSTB") == "02"))
                # no-op 40v9
              else
                override = column_alignment
              end
            end
          else

            override = column_alignment
            preceding_a = preceding_non_faux&.node&.attr("A")
            if preceding_a && /\A(?:L|\d+)/.match?(preceding_a)
              override = :left
            end
          end
        elsif faux? && !preceding.faux? &&
            (expstb = row.node&.attributes&.[]("EXPSTB")&.value) && (expstb != "00") && (expstb != "02") # 18v1 EXPSTB (13v1 not 00) (7v2 not 02)
          override = start_column&.alignment # 12v3 (was :left)
        elsif faux? && !preceding.faux?
          if preceding&.body&.ends_with?("\n") && preceding&.html_attributes&.[](:colspan)&.nonzero?
            override = preceding.alignment
          end
        elsif faux? && (
            (
              preceding&.body&.ends_with?("\n") &&
              (row&.cells&.first&.node&.attr("I") != "22") &&
              (row&.prior_row&.cells&.first&.node&.attr("I") == "22") &&
              (row&.next_row&.cells&.first&.node&.attr("I") == "22")
            ) || (
              preceding&.body&.ends_with?("\n") &&
              (row&.cells&.first&.node&.attr("I") == "22") &&
              (row&.prior_row&.prior_row&.cells&.first&.node&.attr("I") == "22")
            )
          ) # 14v2 faux cell after hard return irregularity
          override = start_column&.alignment
        end

        if override
          result = override
        else
          calculated = start_column&.alignment || result

          if preceding_non_blank&.node&.attr("A") == "01"
            calculated = :left
          end

          if result != calculated
            result = calculated
          end
        end
      end

      if mode == :ecfr_bulkdata
        if body.strip == "X" # 14v2
          result = table.columns[index]&.alignment || result
        end
        if (result == :left) && !following && body.blank? && (index >= table.described_columns.count)
          if preceding_non_blank&.body&.match?(/\AX(\z|#{Spaces::THIN_SPACE}#{Compatibility::PLACEHOLDER_HTML_ADJACENT_ROW_MARKER}\n)/o) # 10v3
            result = nil
          elsif (preceding&.body == BLANK_PLACEHOLDER_CELL_BODY) && (preceding&.preceding&.body == "X\n") # 10v3
            result = nil
          end
        end
      end

      (result == :none) ? nil : result
    end
    memoize :alignment

    def border_classes
      @border_classes ||= [].tap do |classes|
        classes << "border-top-#{border_top}" if border_top
        classes << "border-bottom-#{border_bottom}" if border_bottom
        classes << "border-left-#{border_left}" if border_left
        classes << "border-right-#{border_right}" if border_right && border_right != :none
      end
    end

    def start_column
      table.columns[start_column_index]
    end

    def faux?
      !!@faux
    end

    def first_cell_in_row
      row.all_cells[0]
    end

    def previous_cell_in_row
      if index == 0
        nil
      else
        row.all_cells[index - 1]
      end
    end

    def second_to_last_column
      table.columns[end_column_index - 1] || table.columns[-2]
    end

    def end_column
      table.columns[end_column_index] || table.columns[-1]
    end

    def end_column_index
      start_column_index + colspan - 1
    end

    def first_cell_in_row?
      start_column_index == 0
    end

    def last_cell_in_row?
      if mode == :ecfr_bulkdata && !row.defined_columns_match_table?
        row.cells.index(self) >= if faux?
          row.cells.count - 1
        else
          row.cells.count - 1 - row.faux_cells
        end
      else
        end_column_index + 1 >= table.num_columns
      end
    end

    def first_row_in_table?
      row.first?
    end

    def last_row_in_table?
      return false if is_a?(TableCompilator::HeaderCell)
      row.last?
    end

    def second_to_last_row_in_table?
      return false if is_a?(TableCompilator::HeaderCell)
      row.second_to_last?
    end

    def bottom_right_cell_in_table?
      last_cell_in_row? && last_row_in_table?
    end

    def top_left_cell_in_table?
      first_cell_in_row? && first_row_in_table?
    end

    def following
      row.cells[row.cells.index(self) + 1]
    end

    def preceding
      index = row.cells.index(self) - 1
      return if index < 0
      row.cells[index]
    end

    def preceding_non_blank
      cell = preceding
      while cell && (cell.faux? || cell.blank?)
        cell = cell.preceding
      end
      cell
    end

    def preceding_non_faux
      cell = preceding
      while cell&.faux?
        cell = cell.preceding
      end
      cell
    end

    def wrong_column
      table.columns[index] # intentionally miscalculated (ignoring potential spans)
    end
  end
end
