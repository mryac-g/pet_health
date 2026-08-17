require "test_helper"

class CareRecordTest < ActiveSupport::TestCase
  setup do
    @pet = users(:one).pets.create!(name: "ポチ", species: :dog)
  end

  test "invalid without recorded_at" do
    care_record = @pet.care_records.new(record_type: :meal, recorded_at: nil)
    assert_not care_record.valid?
  end

  test "invalid with a recorded_at in the future" do
    travel_to Time.zone.local(2026, 8, 17, 12, 0, 0) do
      care_record = @pet.care_records.new(
        record_type: :meal, recorded_at: 1.hour.from_now, meal_attributes: { amount: 100 }
      )
      assert_not care_record.valid?
      assert_includes care_record.errors[:recorded_at], "は2026年08月17日 12:00より前の日時にしてください"
    end
  end

  test "valid with a recorded_at of exactly now" do
    travel_to Time.zone.local(2026, 8, 17, 12, 0, 0) do
      care_record = @pet.care_records.new(
        record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 100 }
      )
      assert care_record.valid?
    end
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
      toilet_attributes: { kind: "poop" },
      weight_attributes: { weight: "" }
    )

    assert_nil care_record.weight
  end

  test "invalid when the detail record for record_type is not provided" do
    care_record = @pet.care_records.new(record_type: :weight, recorded_at: Time.current)

    assert_not care_record.valid?
  end

  test "invalid when the nested detail attributes are all blank" do
    care_record = @pet.care_records.new(
      record_type: :weight,
      recorded_at: Time.current,
      weight_attributes: { weight: "" }
    )

    assert_not care_record.valid?
  end

  test "valid without a detail record when record_type is abnormality_note" do
    care_record = @pet.care_records.new(record_type: :abnormality_note, recorded_at: Time.current, note: "様子がおかしい")

    assert care_record.valid?
  end

  test "destroying a care_record destroys its detail record" do
    care_record = @pet.care_records.create!(record_type: :weight, recorded_at: Time.current, weight_attributes: { weight: 4.0 })

    assert_difference("Weight.count", -1) do
      care_record.destroy
    end
  end

  test "detail_summary formats meal, weight and hospital_visit records" do
    meal_record = @pet.care_records.create!(record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 100, completion_rate: 80 })
    assert_equal "100.0g(80.0%)", meal_record.detail_summary

    weight_record = @pet.care_records.create!(record_type: :weight, recorded_at: Time.current, weight_attributes: { weight: 4.2 })
    assert_equal "4.2kg", weight_record.detail_summary

    hospital_record = @pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current, hospital_visit_attributes: { hospital_name: "元気動物病院" })
    assert_equal "元気動物病院", hospital_record.detail_summary
  end

  test "detail_summary returns nil for record types without a detail table" do
    note_record = @pet.care_records.create!(record_type: :abnormality_note, recorded_at: Time.current, note: "様子がおかしい")
    assert_nil note_record.detail_summary
  end

  test "detail_summary shows the completion-rate-adjusted amount instead of the rate label when reflect_meal_completion_rate is true" do
    meal_record = @pet.care_records.create!(
      record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 100, completion_rate: 50 }
    )

    assert_equal "100.0g(半分食べた)", meal_record.detail_summary
    assert_equal "100.0g(200.0g)", meal_record.detail_summary(reflect_meal_completion_rate: true)
  end

  test "detail_summary falls back to the normal amount when reflect_meal_completion_rate is true but no completion_rate was recorded" do
    meal_record = @pet.care_records.create!(record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 100 })

    assert_equal "100.0g", meal_record.detail_summary(reflect_meal_completion_rate: true)
  end

  test "build_graph_series plots the completion-rate-adjusted amount and annotates the label when reflect_meal_completion_rate is true" do
    with_rate = @pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100, completion_rate: 50 })
    without_rate = @pet.care_records.create!(record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 80 })

    series = CareRecord.build_graph_series("meal", [with_rate, without_rate], reflect_meal_completion_rate: true)

    assert_equal "食事量(完食率換算)", series.first[:label]
    assert_equal [200.0, 80.0], series.first[:points].map { |p| p[:y] }
  end

  test "build_graph_series plots the raw amount when reflect_meal_completion_rate is false" do
    with_rate = @pet.care_records.create!(record_type: :meal, recorded_at: Time.current, meal_attributes: { amount: 100, completion_rate: 50 })

    series = CareRecord.build_graph_series("meal", [with_rate])

    assert_equal "食事量", series.first[:label]
    assert_equal [100.0], series.first[:points].map { |p| p[:y] }
  end
end
