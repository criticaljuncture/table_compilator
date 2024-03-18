module TableCompilator
  class StubNode
    def to_xml
      ""
    end

    def content
      nil
    end

    def text
      ""
    end

    def attributes
      {}
    end

    def attr(_key)
      nil
    end
  end
end
