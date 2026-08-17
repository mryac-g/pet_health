require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "guest can upgrade to a real account without a current password, keeping their pets" do
    post guest_sign_in_path
    guest = User.order(:created_at).last
    pet = guest.pets.create!(name: "ポチ", species: :dog)

    patch user_registration_path, params: {
      user: { email: "real@example.com", password: "password123", password_confirmation: "password123" }
    }

    assert_redirected_to root_path
    guest.reload
    assert_equal "real@example.com", guest.email
    assert_not guest.guest?
    assert guest.valid_password?("password123")
    assert_equal [pet.id], guest.pets.pluck(:id)
  end

  test "guest can update without changing the password, leaving it blank" do
    post guest_sign_in_path
    guest = User.order(:created_at).last
    original_encrypted_password = guest.encrypted_password

    patch user_registration_path, params: { user: { email: "real2@example.com", password: "", password_confirmation: "" } }

    guest.reload
    assert_equal "real2@example.com", guest.email
    assert_equal original_encrypted_password, guest.encrypted_password
  end

  test "guest stays a guest if the update fails validation" do
    post guest_sign_in_path
    guest = User.order(:created_at).last

    patch user_registration_path, params: { user: { email: "", password: "password123", password_confirmation: "password123" } }

    guest.reload
    assert guest.guest?
  end

  test "a non-guest user still needs the current password to update" do
    user = User.create!(name: "テスト", email: "regular@example.com", password: "password123", guest: false)
    sign_in user

    patch user_registration_path, params: { user: { email: "changed@example.com", current_password: "wrong-password" } }

    user.reload
    assert_not_equal "changed@example.com", user.email
  end
end
