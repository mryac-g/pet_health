require "test_helper"

class MealTest < ActiveSupport::TestCase
  test "invalid without amount" do
    meal = Meal.new(care_record: care_records(:one), amount: nil)
    assert_not meal.valid?
  end

  test "valid with amount" do
    meal = Meal.new(care_record: care_records(:one), amount: 100)
    assert meal.valid?
  end
end
