module TableCompilator
  class Column
    def self.generate(options)
      table = options.fetch(:table)
      table.described_columns.map do |code|
        new(table: table, code: code)
      end
    end

    attr_reader :table, :code

    delegate :h, :mode, :element_name, to: :table

    def initialize(options)
      @table = options.fetch(:table)
      @code = options.fetch(:code)
      @mode = options[:mode] || :fr
    end

    def width_in_points
      if /\D/.match?(code)
        code.gsub(/\D/, "").to_i
      else
        # figure columns are given as the number figures, not in points
        code.to_i * 5
      end
    end

    def alignment
      if figure?
        result = case modifier_codes
        when /L/
          :left
        when /R/
          :right
        when /C/
          :center
        else
          :right
        end
        if mode == :ecfr_bulkdata
          if modifier_codes.starts_with?("xl")
            result = :left
          elsif modifier_codes == "Cp"
            result = :right
          end
        end
        result
      else
        :left
      end
    end

    def figure?
      code =~ /^\d/
    end

    def border_right
      case modifier_codes
      when /b/
        :bold
      when /p/
        :double
      when /n/
        :none
      end
    end

    def modifier_codes
      code.gsub(/.*\d/, "")
    end

    def index
      table.columns.index(self)
    end

    def first?
      index.zero?
    end

    def last?
      index + 1 == table.columns.size
    end
  end
end
