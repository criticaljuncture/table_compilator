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
    end
  end
end
