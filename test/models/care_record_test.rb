require "test_helper"

class CareRecordTest < ActiveSupport::TestCase
  setup do
    @pet = users(:one).pets.create!(name: "ポチ", species: :dog)
  end

  test "invalid without recorded_at" do
    care_record = @pet.care_records.new(record_type: :meal, recorded_at: nil)
    assert_not care_record.valid?
  end

  test "accepts nested meal attributes and rejects all-blank nested attributes" do
    care_record = @pet.care_records.create!(
      record_type: :meal,
      recorded_at: Time.current,
      meal_attributes: { amount: 100, completion_rate: 90 }
    )

    assert care_record.meal.present?
    assert_equal 100, care_record.meal.amount.to_i
  end

  test "rejects nested weight attributes when all blank" do
    care_record = @pet.care_records.create!(
      record_type: :toilet,
      recorded_at: Time.current,
      weight_attributes: { weight: "" }
    )

    assert_nil care_record.weight
  end

  test "destroying a care_record destroys its detail record" do
    care_record = @pet.care_records.create!(record_type: :weight, recorded_at: Time.current)
    care_record.create_weight!(weight: 4.0)

    assert_difference("Weight.count", -1) do
      care_record.destroy
    end
  end

  test "detail_summary formats meal, weight and hospital_visit records" do
    meal_record = @pet.care_records.create!(record_type: :meal, recorded_at: Time.current)
    meal_record.create_meal!(amount: 100, completion_rate: 80)
    assert_equal "100.0g(80.0%)", meal_record.detail_summary

    weight_record = @pet.care_records.create!(record_type: :weight, recorded_at: Time.current)
    weight_record.create_weight!(weight: 4.2)
    assert_equal "4.2kg", weight_record.detail_summary

    hospital_record = @pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current)
    hospital_record.create_hospital_visit!(hospital_name: "元気動物病院")
    assert_equal "元気動物病院", hospital_record.detail_summary
  end

  test "detail_summary returns nil for record types without a detail table" do
    toilet_record = @pet.care_records.create!(record_type: :toilet, recorded_at: Time.current)
    assert_nil toilet_record.detail_summary
  end
end
