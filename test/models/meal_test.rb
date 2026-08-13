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

  test "invalid when amount contains non-numeric characters" do
    meal = Meal.new(care_record: care_records(:one), amount: "100g")
    assert_not meal.valid?
    assert_includes meal.errors[:amount], "は数字のみで入力してください"
  end

  test "invalid when amount is entirely non-numeric" do
    meal = Meal.new(care_record: care_records(:one), amount: "たくさん")
    assert_not meal.valid?
  end

  test "valid when zenkaku amount normalizes to a plain number" do
    meal = Meal.new(care_record: care_records(:one), amount: "１２０．５")
    assert meal.valid?
  end
end
