require "test_helper"

class MealTypeTest < ActiveSupport::TestCase
  test "invalid without name" do
    meal_type = MealType.new(user: users(:one), name: nil)
    assert_not meal_type.valid?
  end

  test "invalid with a duplicate name for the same user" do
    MealType.create!(user: users(:one), name: "ドライフードX")
    meal_type = MealType.new(user: users(:one), name: "ドライフードX")

    assert_not meal_type.valid?
  end

  test "valid with the same name for a different user" do
    MealType.create!(user: users(:one), name: "ドライフードX")
    meal_type = MealType.new(user: users(:two), name: "ドライフードX")

    assert meal_type.valid?
  end
end
