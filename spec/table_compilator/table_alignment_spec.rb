require File.dirname(__FILE__) + "/../spec_helper"

RSpec.describe TableCompilator::Table do
  include TableHelper

  context "with table alignment" do
    it "reads alignment from the A attributes" do
      table = parse <<-XML
          <GPOTABLE CDEF="6,6,6,6">
            <ROW>
              <ENT A="0">Middle</ENT>
              <ENT A="L0">Left</ENT>
              <ENT A="R0">Right</ENT>
              <ENT A="J0">Justify</ENT>
            </ROW>
          </GPOTABLE>
      XML

      expect(table.body_rows.first.cells.map(&:alignment)).to eql([
        :center,
        :left,
        :right,
        :justify
      ])
    end

    it "reads alignment from the I attributes" do
      table = parse <<-XML
          <GPOTABLE CDEF="s1,1">
            <ROW>
              <ENT I="21">Center</ENT>
              <ENT>Right</ENT>
            </ROW>

            <ROW>
              <ENT I="25">Center</ENT>
              <ENT>Right</ENT>
            </ROW>

            <ROW>
              <ENT I="28">Center</ENT>
            </ROW>
          </GPOTABLE>
      XML

      expect(table.body_rows.map { |r| r.cells.map(&:alignment) }).to eql([
        [:center, :right],
        [:center, :right],
        [:center]
      ])
    end

    context "with column type from the GPOTABLE CDEF attribute" do
      it "works fine for basic attributes" do
        table = parse <<-XML
          <GPOTABLE CDEF="s3,r3,xl3,xs3,xls3,3,3.3,tr3,12C,12L">
            <ROW>
              <ENT>Stub</ENT>
              <ENT>Reading</ENT>
              <ENT>Special Reading</ENT>
              <ENT>Special Reading</ENT>
              <ENT>Special Reading</ENT>
              <ENT>Figure</ENT>
              <ENT>Alignment</ENT>
              <ENT>Tracing</ENT>
              <ENT>Center</ENT>
              <ENT>Left</ENT>
            </ROW>
          </GPOTABLE>
        XML

        expect(table.body_rows.first.cells.map(&:alignment)).to eql([
          :left,
          :left,
          :left,
          :left,
          :left,
          :right,
          :right,
          :left,
          :center,
          :left
        ])
      end

      it "handles colspans" do
        table = parse <<-XML
          <GPOTABLE CDEF="s3,r3,xl3,xs3,xls3,3,3.3,tr3">
            <ROW>
              <ENT A="R3">Stub</ENT>
              <ENT>Special Reading</ENT>
              <ENT A="1">Figure</ENT>
              <ENT>Tracing</ENT>
            </ROW>
          </GPOTABLE>
        XML

        expect(table.body_rows.first.cells.map(&:alignment)).to eql([
          :right,
          :left,
          :center,
          :left
        ])
      end
    end
  end
end
