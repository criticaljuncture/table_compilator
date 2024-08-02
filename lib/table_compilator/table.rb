module TableCompilator
  class Table
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    extend Memoist

    attr_reader :described_columns, :level, :mode, :node

    def self.compile(xml_file_path)
      file = File.open(xml_file_path)
      node = Nokogiri::XML(file).root
      new(node).to_html
    end

    # Initializes a new instance of the class.
    #
    # @param [Nokogiri::XML::Element] node The XML node representing the content.
    #
    # @param [Symbol] mode The mode of operation. Possible values are:
    #   - :fr for Federal Register
    #   - :ecfr for Electronic Code of Federal Regulations
    #   - :ecfr_bulkdata for eCFR bulk data conformity
    #
    # @param [Symbol] level The level of the content. Possible values are:
    #   - :section for section level content
    #   - :appendix for appendix level content
    def initialize(node, mode: nil, level: :section)
      @level = level
      @node = node
      @mode = mode || :fr
    end

    def to_html
      h.content_tag(element_name(:div), class: "table-wrapper") do
        h.content_tag(element_name(:div), width: "100%") do
          width_div_html = "".html_safe
          width_div_html << captions_to_html if (mode == :ecfr_bulkdata) && captions.present?
          width_div_html << h.content_tag(element_name(:div), class: "gpotbl_div") do
            div_html = "".html_safe
            div_html << "\n" if mode == :ecfr
            div_html << h.content_tag(element_name(:table), border: "1", cellpadding: "1", cellspacing: "1",
              class: table_css_classes, frame: "void", width: "100%") do
              html_table = "".html_safe
              if (mode != :ecfr_bulkdata) && captions.present?
                html_table << "\n"
                html_table << captions_to_html
              end

              html_header_rows = "".html_safe
              header_rows.each do |row|
                html_header_rows << row.to_html
              end

              html_table << if mode == :ecfr_bulkdata
                html_header_rows
              else
                thead_html = "".html_safe
                thead_html << "\n" if mode != :ecfr_bulkdata
                thead_html << h.content_tag(element_name(:thead)) do
                  content = "".html_safe
                  content << html_header_rows
                  content << "\n" if mode == :ecfr
                  content
                end
                thead_html
              end

              html_body_rows = "".html_safe
              body_rows.each do |row|
                html_body_rows << row.to_html
              end

              if mode == :ecfr_bulkdata
                html_table << html_body_rows
              else
                html_table << "\n" if mode != :ecfr_bulkdata
                html_table << h.content_tag(element_name(:tbody)) do
                  content = "".html_safe
                  content << html_body_rows
                  content << "\n" if mode != :ecfr_bulkdata
                  content
                end
                html_table << "\n" if mode != :ecfr_bulkdata
                html_table
              end

              html_table << footers_to_html if (mode != :ecfr_bulkdata) && footers.present?
              html_table
            end
            div_html << "\n" if mode == :ecfr
            div_html
          end
          width_div_html << footers_to_html if (mode == :ecfr_bulkdata) && footers.present?
          width_div_html
        end
      end
    end

    def captions_to_html
      return unless captions.present?

      h.content_tag(
        (mode == :ecfr_bulkdata) ? element_name(:div) : element_name(:caption),
        (mode == :ecfr_bulkdata) ? {class: "table_head"} : {}
      ) do
        captions.each do |caption|
          h.concat caption.to_html
        end
      end
    end

    def footers_to_html
      h.capture do
        if footers.present?
          h.concat h.content_tag(
            element_name((mode == :ecfr_bulkdata) ? :div : :tfoot),
            (mode == :ecfr_bulkdata) ? {class: "table_foot"} : {}
          ) {
            footers.each_with_index do |footer, _index|
              h.concat footer.to_html
            end
          }
        end
      end
    end

    def columns
      @described_columns ||= parse_cdef(node&.attr("CDEF"))
      @columns ||= TableCompilator::Column.generate(table: self)
    end

    def captions
      @captions ||= begin
        results = TableCompilator::Caption.generate(table: self, mode: mode)
        if mode == :ecfr_bulkdata
          results.reject! do |caption|
            if caption.node.name != "TTITLE"
              text = caption.node.text
              text = Sgml::BulkdataCompatibility.remove_sgml_compatibility_markers(caption.node.text) if Object.const_defined?(:Sgml)
              text.strip.blank?
            end
          end
        end
        results
      end
    end

    def described_column_count
      @described_columns&.count || 0
    end

    def footers
      @footers ||= TableCompilator::Footer.generate(table: self)
    end

    def header_rows
      @header_rows ||= TableCompilator::HeaderRow.generate(table: self, node: node.xpath("BOXHD"))
    end

    def body_rows
      @body_rows ||= node.css("ROW").map do |row_node|
        TableCompilator::BodyRow.new(table: self, node: row_node)
      end
    end

    def element_name(name)
      case mode
      when :ecfr, :ecfr_bulkdata
        name.to_s.upcase.to_sym
      else
        name
      end
    end

    def defined_columns
      return unless (cols = node.attributes["COLS"].value.to_i).positive?

      cols
    end

    def num_columns
      if mode == :ecfr_bulkdata
        defined_columns || columns.size
      else
        columns.size
      end
    end

    def table_classes
      [].tap do |classes|
        classes << "wide" if total_width_in_points > 250
      end
    end

    def total_width_in_points
      columns.sum(&:width_in_points)
    end

    def helper_controller
      if Object.const_defined?(:ApplicationControllerWithViewHelpers)
        ApplicationControllerWithViewHelpers
      elsif Object.const_defined?(:ApplicationController)
        ApplicationController
      else
        @@base ||= ActionController::Base.new
      end
    end
    memoize :helper_controller

    def h
      helper_controller.helpers
    end
    memoize :h

    def transform(xml, strip: true, footer: false, options: {})
      xslt = "table_contents"
      xslt += ".#{mode}" if %i[ecfr ecfr_bulkdata].include?(mode)

      @text_transformer ||= Nokogiri::XSLT(
        File.open("#{TableCompilator.root}/lib/table_compilator/xslt/matchers/#{xslt}.html.xslt")
      )

      options = {"level" => level.to_s, "colspan_present" => "false", "rowspan_present" => "false"}.merge(options).map do |k, v|
        [k, v.inspect]
      end.flatten

      html = @text_transformer.transform(Nokogiri::XML(xml), options).to_s

      if %i[ecfr ecfr_bulkdata].include?(mode)
        html.gsub!("<br>", "<br/>")
        html.gsub!("</br>", "")
        html.gsub!(%r{\s*\n\s*<br/>}, "\n<br/>") if mode == :ecfr
      end
      if mode == :ecfr_bulkdata
        html.gsub!(/§\s/, "") if %i[ecfr_bulkdata].include?(mode) # 30/250.1715 THIN_SPACE
        html.gsub!(/\n\s*<AC/, "<AC") if footer

        html = Transforms::TitleBuildCorrections.correct(html)

        html
      end
      html = html.strip if strip

      html.html_safe
    end

    def options
      # handle options with parens, like OPTS="L2(1,2,3),4"
      @options ||= (node.attr("OPTS") || "").split(/,(?![^(]*\))/)
    end

    def rule_option
      options
        .detect { |x| x =~ /^L\d(?:\(|$)/ }
    end

    def rules
      return @rules if @rules

      @rules = if rule_option
        case rule_option.sub(/\(.*\).*/, "")
        when "L0"
          []
        when "L1"
          [:horizonal]
        when "L2"
          %i[horizonal down]
        when "L3"
          %i[horizonal side]
        when "L4"
          %i[horizonal down side]
        when "L5"
          # documented as "trim side only", but not really in use
          #  and doesn't make sense on the web
          %i[horizonal side]
        when "L6"
          # documented as "trim side only", but not really in use
          #  and doesn't make sense on the web
          %i[horizonal down side]
        else
          raise "invalid rule option #{rule_option}"
        end
      else
        [] # not specified; what is the default?
      end
    end

    def top_border_style
      case rule_widths[0]
      when 0
        nil
      when 4, 5, 10
        :single
      when 20
        :bold
      else
        :single
      end
    end

    def rule_widths
      rule_widths = [10, 3, 3, 5, 4, 3]
      if rule_option&.include?("(")
        values = rule_option.sub(/^.*\(/, "").sub(")", "").split(",")
        values.each_with_index do |v, i|
          rule_widths[i] = v.to_i if v.present?
        end
      end

      rule_widths
    end

    private

    def parse_cdef(cdef)
      descriptions = cdef
      if mode == :ecfr_bulkdata
        if descriptions.include?(", ") # 40v8 spaces result in a truncated parsing
          descriptions = descriptions.split(", ").map.with_index { |v, i| (i == 0) ? v : v.tr("C", "L") }.join(",")
        end
      end
      descriptions = descriptions.split(/\s*,\s*/)
      descriptions << "" if cdef.match?(/,\s*\z/) # 40v26 trailing seperator expected to produce a blank description
      descriptions
    end

    def table_css_classes
      (mode == :ecfr) ? "gpo_table" : "gpotbl_table"
    end
  end
end

module HtmlCompilator
  module Tables
    Table = TableCompilator::Table
  end
end
