require "test_helper"

class VaccineTypesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get vaccine_types_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's vaccine types" do
    sign_in users(:one)

    get vaccine_types_path

    assert_response :success
    assert_includes response.body, "<span>#{vaccine_types(:one).name}</span>"
    assert_not_includes response.body, "<span>#{vaccine_types(:two).name}</span>"
  end

  test "create adds a vaccine type for the current user" do
    sign_in users(:one)

    assert_difference("VaccineType.count", 1) do
      post vaccine_types_path, params: { vaccine_type: { name: "新しいワクチン" } }
    end

    assert_redirected_to vaccine_types_path
    assert_equal users(:one), VaccineType.last.user
  end

  test "create shows an error for a duplicate name" do
    sign_in users(:one)

    assert_no_difference("VaccineType.count") do
      post vaccine_types_path, params: { vaccine_type: { name: vaccine_types(:one).name } }
    end

    assert_response :unprocessable_content
  end

  test "destroy removes the current user's vaccine type" do
    sign_in users(:one)

    assert_difference("VaccineType.count", -1) do
      delete vaccine_type_path(vaccine_types(:one))
    end

    assert_redirected_to vaccine_types_path
  end

  test "destroy is rejected for another user's vaccine type" do
    sign_in users(:two)

    assert_no_difference("VaccineType.count") do
      delete vaccine_type_path(vaccine_types(:one))
    end

    assert_response :not_found
  end
end
