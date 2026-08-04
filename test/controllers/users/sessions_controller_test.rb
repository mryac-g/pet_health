require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  test "guest creates a guest user and signs them in" do
    assert_difference("User.count", 1) do
      post guest_sign_in_path
    end

    assert User.order(:created_at).last.guest?
    assert_redirected_to root_path
  end
end
