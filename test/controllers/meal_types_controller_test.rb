require "test_helper"

class MealTypesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get meal_types_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's meal types" do
    sign_in users(:one)

    get meal_types_path

    assert_response :success
    assert_includes response.body, "<span>#{meal_types(:one).name}</span>"
    assert_not_includes response.body, "<span>#{meal_types(:two).name}</span>"
  end

  test "create adds a meal type for the current user" do
    sign_in users(:one)

    assert_difference("MealType.count", 1) do
      post meal_types_path, params: { meal_type: { name: "ドライフードX" } }
    end

    assert_redirected_to meal_types_path
    assert_equal users(:one), MealType.last.user
  end

  test "index shows a back link to the referring page when return_to is a safe relative path" do
    sign_in users(:one)

    get meal_types_path(return_to: "/pets/1/care_records/new?record_type=meal")

    assert_response :success
    assert_select "a[href=?]", "/pets/1/care_records/new?record_type=meal"
  end

  test "index falls back to the home page when return_to is an external URL" do
    sign_in users(:one)

    get meal_types_path(return_to: "https://evil.example.com")

    assert_response :success
    assert_select "a[href=?]", root_path
  end

  test "create redirects back to the referring page when return_to is given" do
    sign_in users(:one)

    post meal_types_path, params: { meal_type: { name: "ドライフードY" }, return_to: "/pets/1/care_records/new" }

    assert_redirected_to meal_types_path(return_to: "/pets/1/care_records/new")
  end

  test "create shows an error for a duplicate name" do
    sign_in users(:one)

    assert_no_difference("MealType.count") do
      post meal_types_path, params: { meal_type: { name: meal_types(:one).name } }
    end

    assert_response :unprocessable_content
  end

  test "destroy removes the current user's meal type" do
    sign_in users(:one)

    assert_difference("MealType.count", -1) do
      delete meal_type_path(meal_types(:one))
    end

    assert_redirected_to meal_types_path
  end

  test "destroy is rejected for another user's meal type" do
    sign_in users(:two)

    assert_no_difference("MealType.count") do
      delete meal_type_path(meal_types(:one))
    end

    assert_response :not_found
  end
end
