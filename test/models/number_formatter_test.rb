require "test_helper"

class NumberFormatterTest < ActiveSupport::TestCase
  test "returns nil for nil" do
    assert_nil NumberFormatter.format(nil)
  end

  test "pads a single decimal place when there is no fractional part, to match values that do have one" do
    assert_equal "4.0", NumberFormatter.format(BigDecimal("4.0"))
    assert_equal "4.0", NumberFormatter.format(4.0)
    assert_equal "4.0", NumberFormatter.format(4)
  end

  test "keeps the decimal part when present" do
    assert_equal "4.2", NumberFormatter.format(BigDecimal("4.2"))
    assert_equal "4.25", NumberFormatter.format(4.25)
  end
end
