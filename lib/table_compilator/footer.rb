module TableCompilator
  class Footer
    def self.generate(options)
      table = options.fetch(:table)
      table.node.xpath("TNOTE").map.with_index do |node, i|
        new(
          index: i,
          table: table,
          node: node
        )
      end
    end

    attr_reader :index, :table, :node

    delegate :h, :mode, :element_name, to: :table

    def initialize(options)
      @index = options.fetch(:index)
      @table = options.fetch(:table)
      @node = options.fetch(:node)
    end

    def to_html
      h.content_tag(
        (mode == :ecfr_bulkdata) ? element_name(:p) : element_name(:tr),
        (mode == :ecfr_bulkdata) ? {class: "gpotbl_note"} : {}
      ) do
        if mode == :ecfr_bulkdata
          html = body
          html = "\n".html_safe + html if html.starts_with?("<sup>") # 50v9 Based on acoustic criteria for otariid pinnipeds
          html
        else
          h.concat h.content_tag(element_name(:td), body, colspan: table.num_columns)
        end
      end
    end

    def body
      table.transform(node.to_xml, footer: true)
    end
  end
end
