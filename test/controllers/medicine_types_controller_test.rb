require "test_helper"

class MedicineTypesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get medicine_types_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's medicine types" do
    sign_in users(:one)

    get medicine_types_path

    assert_response :success
    assert_includes response.body, "<span>#{medicine_types(:one).name}</span>"
    assert_not_includes response.body, "<span>#{medicine_types(:two).name}</span>"
  end

  test "create adds a medicine type for the current user" do
    sign_in users(:one)

    assert_difference("MedicineType.count", 1) do
      post medicine_types_path, params: { medicine_type: { name: "新しい薬" } }
    end

    assert_redirected_to medicine_types_path
    assert_equal users(:one), MedicineType.last.user
  end

  test "create shows an error for a duplicate name" do
    sign_in users(:one)

    assert_no_difference("MedicineType.count") do
      post medicine_types_path, params: { medicine_type: { name: medicine_types(:one).name } }
    end

    assert_response :unprocessable_content
  end

  test "destroy removes the current user's medicine type" do
    sign_in users(:one)

    assert_difference("MedicineType.count", -1) do
      delete medicine_type_path(medicine_types(:one))
    end

    assert_redirected_to medicine_types_path
  end

  test "destroy is rejected for another user's medicine type" do
    sign_in users(:two)

    assert_no_difference("MedicineType.count") do
      delete medicine_type_path(medicine_types(:one))
    end

    assert_response :not_found
  end
end
