require "test_helper"

class ToiletTest < ActiveSupport::TestCase
  test "invalid without kind" do
    toilet = Toilet.new(care_record: care_records(:one), kind: nil)
    assert_not toilet.valid?
  end

  test "valid with kind poop and a condition" do
    toilet = Toilet.new(care_record: care_records(:one), kind: :poop, condition: :soft)
    assert toilet.valid?
  end

  test "valid with kind pee and no condition" do
    toilet = Toilet.new(care_record: care_records(:one), kind: :pee)
    assert toilet.valid?
    assert_nil toilet.condition
  end
end
