require "test_helper"

class MealUnitTest < ActiveSupport::TestCase
  test "invalid without name" do
    meal_unit = MealUnit.new(user: users(:one), name: nil)
    assert_not meal_unit.valid?
  end

  test "invalid with a duplicate name for the same user" do
    meal_unit = MealUnit.new(user: users(:one), name: meal_units(:one).name)
    assert_not meal_unit.valid?
  end

  test "valid with the same name for a different user" do
    meal_unit = MealUnit.new(user: users(:two), name: meal_units(:one).name)
    assert meal_unit.valid?
  end
end
