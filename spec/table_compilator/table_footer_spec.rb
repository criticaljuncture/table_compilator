require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe TableCompilator::Table do
  include TableHelper

  context "with table footer" do
    it "supports multiple TNOTE tags" do
      table = parse <<-XML
        <GPOTABLE>
          <TNOTE>Note 1</TNOTE>
          <TNOTE>Note 2</TNOTE>
        </GPOTABLE>
      XML

      expect(table.footers.map(&:body)).to eql(["Note 1", "Note 2"])
    end

    it "supports formatting" do
      table = parse <<-XML
        <GPOTABLE>
          <TNOTE><E T="03">New</E> note</TNOTE>
        </GPOTABLE>
      XML

      expect(table.footers.first.body).to eql "<em>New</em> note"
    end
  end
end
