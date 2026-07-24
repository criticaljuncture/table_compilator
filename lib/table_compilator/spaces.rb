class TableCompilator::Spaces # < ReferenceParser::Spaces
  THIN_SPACE = " "
  EM_SPACE = " "
  EN_SPACE = " "
  FULLWIDTH_SPACE = "　"
  NON_BREAKING_SPACE = " "

  SPACES = [" ", EM_SPACE, EN_SPACE, FULLWIDTH_SPACE, THIN_SPACE]

  def self.any?(text)
    text&.include?(" ") || complex?(text)
  end

  def self.none?(text)
    !any?(text)
  end

  def self.ascii(text)
    simplify(text, " ")
  end

  def self.complex?(text)
    SPACES.detect { |space| text&.include?(space) }
  end

  def self.simplify(text, replacement = nil)
    return text unless text.present?
    text = text.to_s unless text.is_a?(String)
    text = text&.tr(THIN_SPACE, replacement || " ")
    text = text&.tr(EM_SPACE, replacement || " ")
    text&.tr(EN_SPACE, replacement || " ")
  end
end
