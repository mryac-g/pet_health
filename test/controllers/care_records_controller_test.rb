require "test_helper"

class CareRecordsControllerTest < ActionDispatch::IntegrationTest
  test "index redirects unauthenticated users to sign in" do
    get pet_care_records_path(pets(:one))

    assert_redirected_to new_user_session_path
  end

  test "index returns not_found for another user's pet" do
    sign_in users(:two)

    get pet_care_records_path(pets(:one))

    assert_response :not_found
  end

  test "index renders multiple record types without N+1 queries" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago)
    meal_record.create_meal!(amount: 100, completion_rate: 90)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)
    hospital_record = pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current)
    hospital_record.create_hospital_visit!(hospital_name: "元気動物病院")

    get pet_care_records_path(pet)

    assert_response :success
  end

  test "new prefills the meal form with the pet's last used food_name and unit" do
    sign_in users(:one)
    pet = pets(:one)
    record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago)
    record.create_meal!(food_name: "ドライフードA", unit: "g", amount: 100)

    get new_pet_care_record_path(pet)

    assert_response :success
    assert_select "input#care_record_meal_attributes_food_name[value=?]", "ドライフードA"
    assert_select "input#care_record_meal_attributes_unit[value=?]", "g"
  end

  test "create adds a care_record with nested detail attributes for the owner" do
    sign_in users(:one)

    assert_difference("pets(:one).care_records.count", 1) do
      post pet_care_records_path(pets(:one)), params: {
        care_record: {
          record_type: "weight",
          recorded_at: Time.current,
          weight_attributes: { weight: "4.2" }
        }
      }
    end

    assert_redirected_to root_path
    assert_equal 4.2, CareRecord.order(:created_at).last.weight.weight.to_f
  end

  test "create is rejected for another user's pet" do
    sign_in users(:two)

    assert_no_difference("CareRecord.count") do
      post pet_care_records_path(pets(:one)), params: {
        care_record: { record_type: "weight", recorded_at: Time.current }
      }
    end

    assert_response :not_found
  end

  test "destroy removes the care_record for the owner" do
    sign_in users(:one)

    assert_difference("CareRecord.count", -1) do
      delete pet_care_record_path(pets(:one), care_records(:one))
    end

    assert_redirected_to pet_care_records_path(pets(:one))
  end

  test "destroy is rejected for another user's care_record" do
    sign_in users(:two)

    assert_no_difference("CareRecord.count") do
      delete pet_care_record_path(pets(:one), care_records(:one))
    end

    assert_response :not_found
  end
end
