require "test_helper"

class InquiriesControllerTest < ActionDispatch::IntegrationTest
  test "new redirects unauthenticated users to sign in" do
    get new_inquiry_path

    assert_redirected_to new_user_session_path
  end

  test "create saves an inquiry using the current user's name and email" do
    sign_in users(:one)

    assert_difference("Inquiry.count", 1) do
      post inquiries_path, params: { inquiry: { message: "質問があります" } }
    end

    inquiry = Inquiry.last
    assert_equal users(:one), inquiry.user
    assert_equal users(:one).email, inquiry.email
    assert_redirected_to new_inquiry_path
  end

  test "create shows an error when the message is blank" do
    sign_in users(:one)

    assert_no_difference("Inquiry.count") do
      post inquiries_path, params: { inquiry: { message: "" } }
    end

    assert_response :unprocessable_content
  end
end
