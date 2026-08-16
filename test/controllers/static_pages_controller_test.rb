require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "terms is accessible without signing in" do
    get terms_path

    assert_response :success
  end

  test "privacy is accessible without signing in" do
    get privacy_path

    assert_response :success
  end
end
