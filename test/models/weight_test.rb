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
end
