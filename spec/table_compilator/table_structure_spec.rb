require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe TableCompilator::Table do
  include TableHelper

  context "with basic header structure" do
    let(:table) do
      parse <<-XML
        <GPOTABLE COLS="5" CDEF="6,6,6,6,6">
          <BOXHD>
            <CHED H="1"/>
            <CHED H="1">Mango</CHED>
            <CHED H="2">Production</CHED>
            <CHED H="2">Exports</CHED>
            <CHED H="1">Pineapple</CHED>
            <CHED H="2">Production</CHED>
            <CHED H="2">Exports</CHED>
          </BOXHD>
        </GPOTABLE>
      XML
    end

    it "generates the correct number of header rows" do
      expect(table.header_rows.size).to be 2
    end

    it "the cells span the appropriate number of rows" do
      expect(
        table.header_rows.map { |r| r.cells.map(&:rowspan) }
      ).to eql [[2, 1, 1], [1, 1, 1, 1]]
    end

    it "the cells span the appropriate number of columns" do
      expect(
        table.header_rows.map { |r| r.cells.map(&:colspan) }
      ).to eql [[1, 2, 2], [1, 1, 1, 1]]
    end
  end

  context "with complex header structure" do
    let(:table) do
      parse <<-XML
        <GPOTABLE COLS="6" CDEF="6,6,6,6,6,6">
          <BOXHD>
            <CHED H="1">A</CHED>
            <CHED H="1">B</CHED>
            <CHED H="2">C</CHED>
            <CHED H="4">D</CHED>
            <CHED H="4">E</CHED>
            <CHED H="2">F</CHED>
            <CHED H="3">G</CHED>
            <CHED H="4">H</CHED>
            <CHED H="4">I</CHED>
          </BOXHD>
        </GPOTABLE>
      XML
    end

    it "the cells span the appropriate number of rows" do
      expect(
        table.header_rows.map { |r| r.cells.map(&:rowspan) }
      ).to eql [
        [4, 1],
        [2, 1],
        [1],
        [1, 1, 1, 1]
      ]
    end

    it "the cells span the appropriate number of columns" do
      expect(
        table.header_rows.map { |r| r.cells.map(&:colspan) }
      ).to eql [
        [1, 4],
        [2, 2],
        [2],
        [1, 1, 1, 1]
      ]
    end
  end

  it "ignores extra headers" do
    table = parse(<<-XML)
      <GPOTABLE COLS="2" CDEF="6,6">
        <BOXHD>
          <CHED H="1">A</CHED>
          <CHED H="1">B</CHED>
          <CHED H="1">C</CHED>
        </BOXHD>
      </GPOTABLE>
    XML
    expect(table.header_rows.first.cells.map(&:body)).to eql %w[A B]
  end

  it "prints nothing for am empty header" do
    table = parse <<-XML
      <GPOTABLE CDEF="6,6" COLS="2">
        <BOXHD>
          <CHED H="1"></CHED>
          <CHED H="1"></CHED>
        </BOXHD>
        <ROW>
          <ENT>A</ENT>
          <ENT>B</ENT>
        </ROW>
      </GPOTABLE>
    XML

    expect(table.header_rows).to be_empty
  end

  context "with basic body" do
    let(:table) do
      parse <<-XML
        <GPOTABLE CDEF="6,6,6,6">
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
            <ENT>C</ENT>
            <ENT>D</ENT>
          </ROW>
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
            <ENT>C</ENT>
            <ENT>D</ENT>
          </ROW>
        </GPOTABLE>
      XML
    end

    it "has the correct number of rows" do
      expect(table.body_rows.size).to be(2)
    end

    it "the cells don't have any complexity" do
      expect(table.body_rows.map { |r| r.cells.map(&:colspan) })
        .to eql [[1, 1, 1, 1], [1, 1, 1, 1]]
      expect(table.body_rows.map { |r| r.cells.map(&:rowspan) })
        .to eql [[1, 1, 1, 1], [1, 1, 1, 1]]
    end
  end

  context "with body colspans; (A 'spanner designators')" do
    let(:table) do
      parse <<-XML
        <GPOTABLE CDEF="6,6,6,6">
          <ROW>
            <ENT>A</ENT>
            <ENT A="1">BC</ENT>
            <ENT>D</ENT>
          </ROW>
          <ROW>
            <ENT>A</ENT>
            <ENT A="R2">BCD</ENT>
          </ROW>
        </GPOTABLE>
      XML
    end

    it "supports integer values for A" do
      expect(table.body_rows.first.cells.map(&:colspan))
        .to eql [1, 2, 1]
    end

    it "supports values for A that begin with a L/R/J" do
      expect(table.body_rows.second.cells.map(&:colspan))
        .to eql [1, 3]
    end
  end

  context "with body centerheads across entire table I=28" do
    let(:table) do
      parse <<-XML
        <GPOTABLE COLS="4" CDEF="6,6,6,6">
          <ROW>
            <ENT I="28">ABCD</ENT>
          </ROW>
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
            <ENT>C</ENT>
            <ENT>D</ENT>
          </ROW>
        </GPOTABLE>
      XML
    end

    it "makes the cell with I=28 expand to the width of the table" do
      expect(table.body_rows.first.cells.first.colspan).to be(4)
    end

    it "doesn't affect the colspan of other cells" do
      expect(table.body_rows.last.cells.map(&:colspan)).to eql [1, 1, 1, 1]
    end
  end

  context "with support for expanded stub body columns (EXPSTB)" do
    let(:table) do
      parse <<-XML
        <GPOTABLE CDEF="6,6,6,6">
          <ROW EXPSTB="2">
            <ENT>ABC</ENT>
            <ENT>D</ENT>
          </ROW>
          <ROW>
            <ENT>ABC</ENT>
            <ENT>D</ENT>
          </ROW>
          <ROW>
            <ENT>ABC</ENT>
            <ENT>D</ENT>
          </ROW>
          <ROW EXPSTB="0">
            <ENT>A</ENT>
            <ENT>B</ENT>
            <ENT>C</ENT>
            <ENT>D</ENT>
          </ROW>
        </GPOTABLE>
      XML
    end

    it "makes the stub column expand into additional columns when specified" do
      expect(table.body_rows.first.cells.first.colspan).to be(3)
    end

    it "doesn't affect the colspan of the non-stub columns" do
      expect(table.body_rows.first.cells.last.colspan).to be(1)
    end

    it "persists the stub column expansions if not specified" do
      expect(table.body_rows.third.cells.first.colspan).to be(3)
    end

    it "resets the stub column if re-specified" do
      expect(table.body_rows.last.cells.first.colspan).to be(1)
    end
  end

  context "with page breaks" do
    it "handles page breaks in a ROW" do
      table = parse <<-XML
        <GPOTABLE CDEF="6,6" COLS="2">
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
          </ROW>
          <ROW>
            <PRTPAGE P="12345"/>
            <ENT>C</ENT>
            <ENT>D</ENT>
          </ROW>
        </GPOTABLE>
      XML

      expect(table.body_rows.first.page_break_node).to be_nil
      expect(table.body_rows.last.page_break_node).to be_present

      prtpage = table.transform('<PRTPAGE P="12345"/>')
      expect_equal_without_returns(table.body_rows.last.to_html, "<tr class=\"page_break\"><td colspan=\"2\">#{prtpage}</td></tr><tr><td class=\"right\">C</td><td class=\"right\">D</td></tr>")
    end

    it "handles page breaks in a ENT" do
      table = parse <<-XML
        <GPOTABLE CDEF="6,6" COLS="2">
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
          </ROW>
          <ROW>
            <ENT><PRTPAGE P="12345"/>C</ENT>
            <ENT>D</ENT>
          </ROW>
        </GPOTABLE>
      XML

      prtpage = table.transform('<PRTPAGE P="12345"/>')
      expect_equal_without_returns(table.body_rows.last.to_html, "<tr><td class=\"right\">#{prtpage}C</td><td class=\"right\">D</td></tr>")
    end
  end

  context "with malformed tables" do
    xit "handles cells after an I=28" do
      table = parse <<-XML
        <GPOTABLE CDEF="6,6" COLS="2">
          <ROW>
          <ENT I="28">AB</ENT>
          <ENT/>
          </ROW>
        </GPOTABLE>
      XML

      expect(table.body_rows.first.cells.map(&:colspan)).to eql([2])
    end

    it "handles empty rows" do
      table = parse <<-XML
        <GPOTABLE CDEF="6,6" COLS="2">
          <ROW>
            <ENT>A</ENT>
            <ENT>B</ENT>
          </ROW>
          <ROW />
        </GPOTABLE>
      XML
      table.to_html
      expect(table.body_rows.last.to_html).to be_nil
    end
  end
end
