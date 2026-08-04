require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get root_path

    assert_response :success
  end

  test "index lists the current user's pets when signed in" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "body", text: /#{pets(:one).name}/
  end
end
