require "test_helper"

class WeightTest < ActiveSupport::TestCase
  test "invalid without weight" do
    weight = Weight.new(care_record: care_records(:one), weight: nil)
    assert_not weight.valid?
  end

  test "valid with weight" do
    weight = Weight.new(care_record: care_records(:one), weight: 4.2)
    assert weight.valid?
  end

  test "normalizes zenkaku digits when setting weight" do
    weight = Weight.new(care_record: care_records(:one), weight: "４．２")
    assert_equal BigDecimal("4.2"), weight.weight
  end

  test "invalid when weight contains non-numeric characters" do
    weight = Weight.new(care_record: care_records(:one), weight: "4.2kg")
    assert_not weight.valid?
    assert_includes weight.errors[:weight], "は数字のみで入力してください"
  end
end
