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

  test "valid with the hard condition" do
    toilet = Toilet.new(care_record: care_records(:one), kind: :poop, condition: :hard)
    assert toilet.valid?
  end

  test "CONDITION_OPTIONS lists the five expected conditions in order" do
    assert_equal %w[hard normal soft watery absent], Toilet::CONDITION_OPTIONS.map(&:first)
    assert_equal ["かたい", "ふつう", "やわらかい", "下痢", "出なかった"], Toilet::CONDITION_OPTIONS.map { |o| o[1] }
  end
end
