require "test_helper"

class PetTest < ActiveSupport::TestCase
  test "invalid without name" do
    pet = Pet.new(user: users(:one), name: nil, species: :dog)
    assert_not pet.valid?
  end

  test "valid with name and species" do
    pet = Pet.new(user: users(:one), name: "ポチ", species: :dog)
    assert pet.valid?
  end

  test "weight_series returns date/value pairs ordered by recorded_at" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    older = pet.care_records.create!(record_type: :weight, recorded_at: 2.days.ago)
    older.create_weight!(weight: 4.0)
    newer = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    newer.create_weight!(weight: 4.2)

    series = pet.weight_series

    assert_equal 2, series.size
    assert_equal 4.0, series.first[:value]
    assert_equal 4.2, series.second[:value]
  end

  test "weight_series skips weight care_records without a weight record" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: Time.current)

    assert_empty pet.weight_series
  end

  test "summary_text groups records by type within Japanese labels" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    cr = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    cr.create_weight!(weight: 4.2)

    text = pet.summary_text

    assert_includes text, "ポチのケア記録サマリー"
    assert_includes text, "■ 体重"
    assert_includes text, "4.2kg"
  end

  test "summary_text reports no records when none exist in range" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    assert_includes pet.summary_text, "該当期間の記録はありません"
  end
end
