require "test_helper"

class HospitalNamesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get hospital_names_path

    assert_redirected_to new_user_session_path
  end

  test "index only lists the current user's hospital names" do
    sign_in users(:one)

    get hospital_names_path

    assert_response :success
    assert_includes response.body, "<span>#{hospital_names(:one).name}</span>"
    assert_not_includes response.body, "<span>#{hospital_names(:two).name}</span>"
  end

  test "create adds a hospital name for the current user" do
    sign_in users(:one)

    assert_difference("HospitalName.count", 1) do
      post hospital_names_path, params: { hospital_name: { name: "新しい病院" } }
    end

    assert_redirected_to hospital_names_path
    assert_equal users(:one), HospitalName.last.user
  end

  test "create shows an error for a duplicate name" do
    sign_in users(:one)

    assert_no_difference("HospitalName.count") do
      post hospital_names_path, params: { hospital_name: { name: hospital_names(:one).name } }
    end

    assert_response :unprocessable_content
  end

  test "destroy removes the current user's hospital name" do
    sign_in users(:one)

    assert_difference("HospitalName.count", -1) do
      delete hospital_name_path(hospital_names(:one))
    end

    assert_redirected_to hospital_names_path
  end

  test "destroy is rejected for another user's hospital name" do
    sign_in users(:two)

    assert_no_difference("HospitalName.count") do
      delete hospital_name_path(hospital_names(:one))
    end

    assert_response :not_found
  end
end
