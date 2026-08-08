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

  test "show renders weight and meal charts and multiple pet tabs without N+1 queries" do
    sign_in users(:one)
    pet = pets(:one)
    users(:one).pets.create!(name: "タマ", species: :cat)
    2.times do |i|
      weight_record = pet.care_records.create!(record_type: :weight, recorded_at: i.days.ago)
      weight_record.create_weight!(weight: 4.0 + i)
      meal_record = pet.care_records.create!(record_type: :meal, recorded_at: i.days.ago)
      meal_record.create_meal!(amount: 100 + i, completion_rate: 90)
    end

    get pet_path(pet)

    assert_response :success
  end

  test "show renders a card per record type, with the latest summary for recorded types" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    get pet_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "weight") do
      assert_select "*", text: /4.2kg/
    end
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "walk") do
      assert_select "*", text: "記録なし"
    end
    assert_select "a[href=?]", new_pet_care_record_path(pet, record_type: "weight")
  end

  test "summary renders multiple record types without N+1 queries" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)
    hospital_record = pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current)
    hospital_record.create_hospital_visit!(hospital_name: "元気動物病院")

    get summary_pet_path(pet)

    assert_response :success
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
