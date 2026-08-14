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

  test "record_type_keys defaults to all record types for a new pet" do
    pet = Pet.new(user: users(:one), name: "ポチ", species: :dog)

    assert_equal CareRecord::RECORD_TYPE_LABELS.keys, pet.record_type_keys
  end

  test "record_type_keys= sets an explicit subset instead of the default" do
    pet = Pet.new(user: users(:one), name: "ポチ", species: :dog, record_type_keys: %w[meal walk])

    assert_equal %w[meal walk], pet.record_type_keys
  end

  test "record_type_keys= replaces the enabled set on save without touching unrelated types" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog, record_type_keys: %w[meal weight])

    pet.update!(record_type_keys: %w[meal])

    assert_equal %w[meal], pet.reload.record_type_keys
    assert_equal 1, pet.pet_record_types.count
  end

  test "invalid with an empty record_type_keys" do
    pet = Pet.new(user: users(:one), name: "ポチ", species: :dog, record_type_keys: [])

    assert_not pet.valid?
    assert_includes pet.errors[:record_type_keys], "を1つ以上選択してください"
  end

  test "a failed update does not delete existing pet_record_types" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog, record_type_keys: %w[meal weight])

    pet.update(name: "", record_type_keys: [])

    assert_equal %w[meal weight], pet.reload.record_type_keys
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

  test "summary_text filters to the given record_types" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 100)

    text = pet.summary_text(record_types: %w[weight])

    assert_includes text, "■ 体重"
    assert_not_includes text, "■ 食事"
  end

  test "summary_text filters to the given date range" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10").create_weight!(weight: 4.2)

    text = pet.summary_text(from: Date.parse("2026-08-05"), to: Date.parse("2026-08-15"))

    assert_includes text, "08/10: 4.2kg"
    assert_not_includes text, "08/01: 4kg"
  end

  test "summary_text with from: nil includes records from before the default 30-day lookback" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: 100.days.ago).create_weight!(weight: 4.0)

    text = pet.summary_text(from: nil, record_types: %w[weight])

    assert_includes text, "期間: 全期間"
    assert_includes text, "4kg"
  end

  test "summary_text groups by date instead of record_type when group_by is date" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00")
    weight_record.create_weight!(weight: 4.2)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: "2026-08-10 12:00")
    meal_record.create_meal!(amount: 100)
    other_day = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00")
    other_day.create_weight!(weight: 4.0)

    text = pet.summary_text(group_by: "date")

    assert_includes text, "■ 2026/08/10"
    assert_includes text, "体重: 4.2kg"
    assert_includes text, "食事: "
    assert_not_includes text, "■ 体重"
    assert_not_includes text, "■ 食事"
  end

  test "summary_entries carries the same text lines as summary_text, plus the care_record for each record line" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    entries = pet.summary_entries

    assert_equal [{ header: "体重" }, { care_record: weight_record, text: entries.last[:text] }], entries
    assert_includes entries.last[:text], "4.2kg"
    assert_includes pet.summary_text, entries.last[:text]
  end

  test "summary_entries returns an empty array when there is nothing in range" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    assert_equal [], pet.summary_entries
  end

  test "summary_graph_series groups series by record_type for graphable types within range" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)
    toilet_record = pet.care_records.create!(record_type: :toilet, recorded_at: 1.day.ago)
    toilet_record.create_toilet!(kind: "pee")
    old_weight = pet.care_records.create!(record_type: :weight, recorded_at: 60.days.ago)
    old_weight.create_weight!(weight: 3.0)

    series_by_type = pet.summary_graph_series(from: 30.days.ago.to_date)

    assert_equal %w[weight], series_by_type.keys
    assert_equal 1, series_by_type["weight"].first[:points].size
    assert_equal 4.2, series_by_type["weight"].first[:points].first[:y]
  end

  test "summary_graph_series returns an empty hash when there is nothing graphable" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :toilet, recorded_at: 1.day.ago).create_toilet!(kind: "pee")

    assert_equal({}, pet.summary_graph_series)
  end

  test "summary_graph_series filters to the given record_types" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 100)

    series_by_type = pet.summary_graph_series(record_types: %w[weight])

    assert_equal %w[weight], series_by_type.keys
  end

  test "summary_graph_series filters to the given date range" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10").create_weight!(weight: 4.2)

    series_by_type = pet.summary_graph_series(from: Date.parse("2026-08-05"), to: Date.parse("2026-08-15"))

    assert_equal 1, series_by_type["weight"].first[:points].size
    assert_equal 4.2, series_by_type["weight"].first[:points].first[:y]
  end

  test "summary_graph_series filters meal records to the given meal_unit, since g and 袋 aren't comparable" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago).create_meal!(amount: 100, unit: "g")
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 2, unit: "袋")

    series_by_type = pet.summary_graph_series(record_types: %w[meal], meal_unit: "g")

    assert_equal [100.0], series_by_type["meal"].first[:points].map { |p| p[:y] }
  end

  test "summary_graph_series filters medication records to the given medication_unit" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :medication, recorded_at: 2.days.ago)
      .create_medication!(medicine_name: "薬A", dosage_amount: 1, dosage_unit: "錠")
    pet.care_records.create!(record_type: :medication, recorded_at: 1.day.ago)
      .create_medication!(medicine_name: "薬B", dosage_amount: 5, dosage_unit: "ml")

    series_by_type = pet.summary_graph_series(record_types: %w[medication], medication_unit: "錠")

    assert_equal [1.0], series_by_type["medication"].first[:points].map { |p| p[:y] }
  end

  test "summary_entries and summary_text reflect the same meal_unit filter" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago).create_meal!(food_name: "フードA", amount: 100, unit: "g")
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(food_name: "フードB", amount: 2, unit: "袋")

    entries = pet.summary_entries(record_types: %w[meal], meal_unit: "g")
    text = pet.summary_text(record_types: %w[meal], meal_unit: "g")

    assert_equal 1, entries.count { |e| e[:care_record] }
    assert_includes text, "フードA"
    assert_not_includes text, "フードB"
  end

  test "summary_graph_series with no meal_unit given keeps mixing units, as before" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago).create_meal!(amount: 100, unit: "g")
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 2, unit: "袋")

    series_by_type = pet.summary_graph_series(record_types: %w[meal])

    assert_equal 2, series_by_type["meal"].first[:points].size
  end

  test "last_meal returns the most recently created meal for the pet" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    older = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago)
    older.create_meal!(food_name: "古いフード", amount: 100)
    newer = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago)
    newer.create_meal!(food_name: "新しいフード", amount: 120)

    assert_equal "新しいフード", pet.last_meal.food_name
  end

  test "last_meal returns nil when the pet has no meal records" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    assert_nil pet.last_meal
  end

  test "last_medication returns the most recently created medication for the pet" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    older = pet.care_records.create!(record_type: :medication, recorded_at: 2.days.ago)
    older.create_medication!(medicine_name: "古い薬", dosage_amount: 1, dosage_unit: "錠")
    newer = pet.care_records.create!(record_type: :medication, recorded_at: 1.day.ago)
    newer.create_medication!(medicine_name: "新しい薬", dosage_amount: 2, dosage_unit: "ml")

    assert_equal "新しい薬", pet.last_medication.medicine_name
  end

  test "last_medication returns nil when the pet has no medication records" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    assert_nil pet.last_medication
  end

  test "icon_download_url falls back to icon_url when no icon has been uploaded" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog, icon_url: "https://example.com/icon.png")

    assert_equal "https://example.com/icon.png", pet.icon_download_url
  end

  test "icon_download_url uses a presigned url when an icon has been uploaded" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog, icon_storage_key: "pets/x/uuid.png")
    original_method = SupabaseStorage.method(:presigned_url)

    begin
      SupabaseStorage.define_singleton_method(:presigned_url) { |*| "https://example.com/signed-icon" }
      assert_equal "https://example.com/signed-icon", pet.icon_download_url
    ensure
      SupabaseStorage.define_singleton_method(:presigned_url, original_method)
    end
  end

  test "upload_icon! raises UnsupportedIconContentTypeError for disallowed content types" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "test.txt")

    assert_raises(Pet::UnsupportedIconContentTypeError) { pet.upload_icon!(file) }
  end

  test "upload_icon! raises IconTooLargeError for oversized files" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    oversized_content = "a" * (Pet::MAX_ICON_SIZE + 1)
    file = Rack::Test::UploadedFile.new(StringIO.new(oversized_content), "image/png", original_filename: "test.png")

    assert_raises(Pet::IconTooLargeError) { pet.upload_icon!(file) }
  end

  test "upload_icon! uploads the file and sets icon_storage_key" do
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "image/png", original_filename: "icon.png")
    original_method = SupabaseStorage.method(:upload)

    begin
      SupabaseStorage.define_singleton_method(:upload) { |*| true }
      pet.upload_icon!(file)
    ensure
      SupabaseStorage.define_singleton_method(:upload, original_method)
    end

    assert pet.icon_storage_key.present?
    assert pet.icon_storage_key.end_with?(".png")
  end
end
