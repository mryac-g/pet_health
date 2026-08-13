require "test_helper"

class DeviseViewsTest < ActionDispatch::IntegrationTest
  test "sign up page renders bordered inputs and the correct Japanese submit label" do
    get new_user_registration_path

    assert_response :success
    assert_select "h1", text: "アカウント登録"
    assert_select "input[type=email].input-bordered"
    assert_select "input[type=submit][value=?]", "アカウント登録"
  end

  test "sign up creates a user and shows validation errors in the app's alert style" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: { email: "devise_view_test@example.com", password: "password12345", password_confirmation: "mismatched" }
      }
    end

    assert_select "div[role=alert].alert-error"

    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: { email: "devise_view_test@example.com", password: "password12345", password_confirmation: "password12345" }
      }
    end
  end

  test "sign in page renders bordered inputs and the correct Japanese submit label" do
    get new_user_session_path

    assert_response :success
    assert_select "h1", text: "ログイン"
    assert_select "input[type=email].input-bordered"
    assert_select "input[type=submit][value=?]", "ログイン"
  end
end
