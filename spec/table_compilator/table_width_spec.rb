require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe TableCompilator::Table do
  include TableHelper

  context "with table width" do
    context "with column widths" do
      it "reads the widths from the CDEF attribute" do
        table = parse <<-XML
          <GPOTABLE CDEF="2,r1,xl2,xs4"></GPOTABLE>
        XML

        expect(table.columns.map(&:width_in_points)).to eql [
          10,
          1,
          2,
          4
        ]
      end

      it "counts figure columns as five points per figure, ignoring modifiers" do
        table = parse <<-XML
          <GPOTABLE CDEF="12,12C,8L,4Cb,6Rp"></GPOTABLE>
        XML

        expect(table.columns.map(&:width_in_points)).to eql [60, 60, 40, 20, 30]
      end

      it "counts stub and reading columns as points" do
        table = parse <<-XML
          <GPOTABLE CDEF="s50,r45,xs30,xl2"></GPOTABLE>
        XML

        expect(table.columns.map(&:width_in_points)).to eql [50, 45, 30, 2]
      end
    end

    context "with total width" do
      it "sums the column widths" do
        table = parse <<-XML
          <GPOTABLE CDEF="s50,12C,8L"></GPOTABLE>
        XML

        expect(table.total_width_in_points).to be 150
      end
    end

    context "with data-point-width" do
      let(:xml) do
        <<-XML
          <GPOTABLE COLS="3" OPTS="L2" CDEF="s50,12C,8L">
            <BOXHD>
              <CHED H="1">A</CHED>
              <CHED H="1">B</CHED>
              <CHED H="1">C</CHED>
            </BOXHD>
            <ROW><ENT I="01">x</ENT><ENT>1</ENT><ENT>2</ENT></ROW>
          </GPOTABLE>
        XML
      end

      def table_for(mode)
        TableCompilator::Table.new(Nokogiri::XML(xml).root, mode: mode)
      end

      it "is added to the table in :ecfr mode" do
        html = table_for(:ecfr).to_html
        expect(html).to include('data-point-width="150"')
        expect(Nokogiri::HTML.fragment(html).at_css("table.gpo_table")["data-point-width"]).to eql "150"
      end

      it "is not added in :fr mode" do
        expect(table_for(:fr).to_html).not_to include("data-point-width")
      end

      it "is not added in :ecfr_bulkdata mode" do
        stub_const("Transforms::TitleBuildCorrections", Class.new { def self.correct(html) = html })
        expect(table_for(:ecfr_bulkdata).to_html).not_to include("data-point-width")
      end
    end
  end
end
