module TableHelper
  def parse(xml)
    TableCompilator::Table.new(
      Nokogiri::XML(xml).root
    )
  end
end
