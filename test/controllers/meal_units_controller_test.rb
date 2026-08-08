require "test_helper"

class MealUnitsControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get meal_units_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's meal units" do
    sign_in users(:one)

    get meal_units_path

    assert_response :success
    assert_includes response.body, "<span>#{meal_units(:one).name}</span>"
    assert_not_includes response.body, "<span>#{meal_units(:two).name}</span>"
  end

  test "create adds a meal unit for the current user" do
    sign_in users(:one)

    assert_difference("MealUnit.count", 1) do
      post meal_units_path, params: { meal_unit: { name: "缶" } }
    end

    assert_redirected_to meal_units_path
    assert_equal users(:one), MealUnit.last.user
  end

  test "create shows an error for a duplicate name" do
    sign_in users(:one)

    assert_no_difference("MealUnit.count") do
      post meal_units_path, params: { meal_unit: { name: meal_units(:one).name } }
    end

    assert_response :unprocessable_content
  end

  test "destroy removes the current user's meal unit" do
    sign_in users(:one)

    assert_difference("MealUnit.count", -1) do
      delete meal_unit_path(meal_units(:one))
    end

    assert_redirected_to meal_units_path
  end

  test "destroy is rejected for another user's meal unit" do
    sign_in users(:two)

    assert_no_difference("MealUnit.count") do
      delete meal_unit_path(meal_units(:one))
    end

    assert_response :not_found
  end
end
