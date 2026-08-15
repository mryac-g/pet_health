require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "display_or_unselected returns 未選択 for blank values" do
    assert_equal "未選択", display_or_unselected(nil)
    assert_equal "未選択", display_or_unselected("")
  end

  test "display_or_unselected pads a single decimal place for whole numbers" do
    assert_equal "4.0km", display_or_unselected(BigDecimal("4.0"), suffix: "km")
  end

  test "display_or_unselected keeps the decimal point for fractional numbers" do
    assert_equal "4.2km", display_or_unselected(BigDecimal("4.2"), suffix: "km")
  end

  test "display_or_unselected returns non-numeric values as-is" do
    assert_equal "錠", display_or_unselected("錠")
  end
end
