require "test_helper"

class NumberFormatterTest < ActiveSupport::TestCase
  test "returns nil for nil" do
    assert_nil NumberFormatter.format(nil)
  end

  test "strips the decimal point when there is no fractional part" do
    assert_equal "4", NumberFormatter.format(BigDecimal("4.0"))
    assert_equal "4", NumberFormatter.format(4.0)
    assert_equal "4", NumberFormatter.format(4)
  end

  test "keeps the decimal part when present" do
    assert_equal "4.2", NumberFormatter.format(BigDecimal("4.2"))
    assert_equal "4.25", NumberFormatter.format(4.25)
  end
end
