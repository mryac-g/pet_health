require "test_helper"

class Admin::InquiriesControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get admin_inquiries_path

    assert_redirected_to new_user_session_path
  end

  test "index redirects non-admin users to root" do
    sign_in users(:one)

    get admin_inquiries_path

    assert_redirected_to root_path
  end

  test "index lists inquiries for admin users" do
    sign_in users(:admin_user)
    inquiry = Inquiry.create!(user: users(:one), name: users(:one).name, email: users(:one).email, message: "質問があります")

    get admin_inquiries_path

    assert_response :success
    assert_includes response.body, inquiry.email
  end

  test "show is rejected for non-admin users" do
    sign_in users(:one)
    inquiry = Inquiry.create!(user: users(:one), name: users(:one).name, email: users(:one).email, message: "質問があります")

    get admin_inquiry_path(inquiry)

    assert_redirected_to root_path
  end
end
