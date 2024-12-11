module ComparisonHelper
  def expect_equal_without_returns(a, b)
    expect(without_returns(a)).to eq(without_returns(b))
  end

  private

  def without_returns(text)
    text&.delete("\n")
  end
end
