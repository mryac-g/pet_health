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
