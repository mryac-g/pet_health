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

  test "normalizes zenkaku digits when setting amount" do
    meal = Meal.new(care_record: care_records(:one), amount: "１２０．５")
    assert_equal BigDecimal("120.5"), meal.amount
  end

  test "leaves a numeric amount unchanged" do
    meal = Meal.new(care_record: care_records(:one), amount: 120.5)
    assert_equal BigDecimal("120.5"), meal.amount
  end
end
