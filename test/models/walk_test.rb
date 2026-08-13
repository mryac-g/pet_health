require "test_helper"

class WalkTest < ActiveSupport::TestCase
  test "valid without duration_minutes or distance" do
    walk = Walk.new(care_record: care_records(:one))
    assert walk.valid?
  end

  test "normalizes zenkaku digits when setting duration_minutes" do
    walk = Walk.new(care_record: care_records(:one), duration_minutes: "３０")
    assert_equal 30, walk.duration_minutes
  end

  test "normalizes zenkaku digits when setting distance" do
    walk = Walk.new(care_record: care_records(:one), distance: "１．５")
    assert_equal BigDecimal("1.5"), walk.distance
  end

  test "invalid when duration_minutes contains non-numeric characters" do
    walk = Walk.new(care_record: care_records(:one), duration_minutes: "30分")
    assert_not walk.valid?
    assert_includes walk.errors[:duration_minutes], "は数字のみで入力してください"
  end

  test "invalid when distance contains non-numeric characters" do
    walk = Walk.new(care_record: care_records(:one), distance: "1.5km")
    assert_not walk.valid?
    assert_includes walk.errors[:distance], "は数字のみで入力してください"
  end
end
