require "test_helper"

class WaterTest < ActiveSupport::TestCase
  test "invalid without amount" do
    water = Water.new(care_record: care_records(:one), amount: nil)
    assert_not water.valid?
  end

  test "valid with amount" do
    water = Water.new(care_record: care_records(:one), amount: 100)
    assert water.valid?
  end

  test "normalizes zenkaku digits when setting amount" do
    water = Water.new(care_record: care_records(:one), amount: "１２０．５")
    assert_equal BigDecimal("120.5"), water.amount
  end

  test "leaves a numeric amount unchanged" do
    water = Water.new(care_record: care_records(:one), amount: 120.5)
    assert_equal BigDecimal("120.5"), water.amount
  end
end
