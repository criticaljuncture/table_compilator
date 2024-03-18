require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe TableCompilator::Table do
  include TableHelper

  context "with missing cells" do
    context "with table body" do
      it "adds missing cells at end of row" do
        table = parse <<-XML
          <GPOTABLE COLS="3" OPTS="L2(1)" CDEF="1,1,1">
            <ROW>
              <ENT I="22">A</ENT>
            </ROW>
          </GPOTABLE>
        XML

        expect(table.body_rows.first.cells.size).to be(3)
      end

      it "handles colspan" do
        table = parse <<-XML
          <GPOTABLE COLS="3" OPTS="L2(1)" CDEF="1,1,1">
            <ROW>
              <ENT A="1">AB</ENT>
            </ROW>
          </GPOTABLE>
        XML

        expect(table.body_rows.first.cells.size).to be(2)
      end
    end
  end
end
