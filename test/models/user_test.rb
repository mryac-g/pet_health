require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid with name, email and password" do
    user = User.new(name: "テスト", email: "new@example.com", password: "password123")
    assert user.valid?
  end

  test "invalid without email" do
    user = User.new(name: "テスト", email: nil, password: "password123")
    assert_not user.valid?
  end

  test "invalid with duplicate email" do
    user = User.new(name: "テスト", email: users(:one).email, password: "password123")
    assert_not user.valid?
  end

  test "has_many pets destroys dependent pets" do
    user = User.create!(name: "テスト", email: "owner@example.com", password: "password123")
    pet = user.pets.create!(name: "ポチ", species: :dog)

    assert_difference("Pet.count", -1) do
      user.destroy
    end
    assert_not Pet.exists?(pet.id)
  end
end
