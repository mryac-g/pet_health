require "test_helper"

class PetsControllerTest < ActionDispatch::IntegrationTest
  test "show redirects unauthenticated users to sign in" do
    get pet_path(pets(:one))

    assert_redirected_to new_user_session_path
  end

  test "show renders for the owner" do
    sign_in users(:one)

    get pet_path(pets(:one))

    assert_response :success
  end

  test "show returns not_found for another user's pet" do
    sign_in users(:two)

    get pet_path(pets(:one))

    assert_response :not_found
  end

  test "create registers a pet for the current user" do
    sign_in users(:one)

    assert_difference("users(:one).pets.count", 1) do
      post pets_path, params: { pet: { name: "ポチ", species: "dog" } }
    end

    assert_redirected_to pet_path(Pet.order(:created_at).last)
  end

  test "create re-renders the form when invalid" do
    sign_in users(:one)

    assert_no_difference("Pet.count") do
      post pets_path, params: { pet: { name: "", species: "dog" } }
    end

    assert_response :unprocessable_content
  end
end
