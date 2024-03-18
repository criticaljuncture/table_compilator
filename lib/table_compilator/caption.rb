module TableCompilator
  class Caption
    def self.generate(options)
      table = options.fetch(:table)
      mode = options.fetch(:mode)

      if mode == :ecfr_bulkdata
        table.node.xpath("TTITLE|NRTTITLE|TDESC[1]").select { |node| node.text.present? || Spaces.complex?(node.text) }
      else
        table.node.xpath("TTITLE|NRTTITLE|TDESC").select { |node| node.text.present? }
      end.map do |node|
        new(
          table: table,
          node: node
        )
      end
    end

    attr_reader :table, :node

    delegate :h, :mode, :element_name, to: :table

    def initialize(options)
      @table = options.fetch(:table)
      @node = options.fetch(:node)
    end

    def to_html
      h.content_tag(element_name(:p), body, class: type)
    end

    def type
      case mode
      when :ecfr_bulkdata
        case node.name
        when "TDESC"
          "gpotbl_description"
        else
          "gpotbl_title"
        end
      else
        case node.name
        when "TTITLE", "NRTTITLE"
          :title
        when "TDESC"
          :headnote
        else
          raise "unknown caption type: #{node.name}"
        end
      end
    end

    def body
      result = table.transform(node.to_xml, strip: type != "gpotbl_title" && type != "gpotbl_description")
      result = result.strip if mode == :ecfr_bulkdata && (type == "gpotbl_title") && !result.present?
      result
    end
  end
end
