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

  test "index renders a header shortcut back to the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)

    get pet_care_records_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_path(pet), text: "#{pet.name}のページに戻る"
  end

  test "show renders an inline image for image attachments" do
    sign_in users(:one)
    original_method = SupabaseStorage.method(:presigned_url)

    begin
      SupabaseStorage.define_singleton_method(:presigned_url) { |*| "https://example.com/signed-url" }
      get pet_care_record_path(pets(:one), care_records(:one))
    ensure
      SupabaseStorage.define_singleton_method(:presigned_url, original_method)
    end

    assert_response :success
    assert_select "img[src=?]", "https://example.com/signed-url"
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

  test "index filters records by record_type when given" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago)
    meal_record.create_meal!(amount: 100, completion_rate: 90)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "h1", text: "体重の記録一覧"
    assert_select "li", count: pet.care_records.weight.count
    assert_select "a", text: "＋"
  end

  test "index does not show a add button when not filtered by record_type" do
    sign_in users(:one)

    get pet_care_records_path(pets(:one))

    assert_response :success
    assert_select "a", text: "＋", count: 0
  end

  test "index ignores an invalid record_type param" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago)
    meal_record.create_meal!(amount: 100, completion_rate: 90)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "not_a_real_type")

    assert_response :success
    assert_select "h1", text: "全記録一覧"
    assert_select "li", count: pet.care_records.count
  end

  test "new preselects the record_type given in params" do
    sign_in users(:one)

    get new_pet_care_record_path(pets(:one), record_type: "water")

    assert_response :success
    assert_select "p", text: "水"
    assert_select "input[name=?]", "care_record[water_attributes][amount]"
  end

  test "new falls back to meal for an invalid record_type param" do
    sign_in users(:one)

    get new_pet_care_record_path(pets(:one), record_type: "not_a_real_type")

    assert_response :success
    assert_select "p", text: "食事"
    assert_select "input[name=?]", "care_record[meal_attributes][amount]"
  end

  test "new renders the preset-management links with a modal trigger action and a matching empty frame" do
    sign_in users(:one)

    get new_pet_care_record_path(pets(:one))

    assert_response :success
    assert_select "a[data-action=?]", "preset-modal#open", count: 2
    assert_select "turbo-frame#preset_list"
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

    assert_redirected_to pet_path(pets(:one))
    assert_equal 4.2, CareRecord.order(:created_at).last.weight.weight.to_f
  end

  test "create adds a toilet care_record with a condition when kind is poop" do
    sign_in users(:one)

    post pet_care_records_path(pets(:one)), params: {
      care_record: {
        record_type: "toilet",
        recorded_at: Time.current,
        toilet_attributes: { kind: "poop", condition: "soft" }
      }
    }

    toilet = CareRecord.order(:created_at).last.toilet
    assert_equal "poop", toilet.kind
    assert_equal "soft", toilet.condition
  end

  test "create adds a toilet care_record without a condition when kind is pee" do
    sign_in users(:one)

    post pet_care_records_path(pets(:one)), params: {
      care_record: {
        record_type: "toilet",
        recorded_at: Time.current,
        toilet_attributes: { kind: "pee" }
      }
    }

    toilet = CareRecord.order(:created_at).last.toilet
    assert_equal "pee", toilet.kind
    assert_nil toilet.condition
  end

  test "create still saves the care_record when an attached file has an unsupported content type" do
    sign_in users(:one)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "test.txt")

    assert_difference("pets(:one).care_records.count", 1) do
      post pet_care_records_path(pets(:one)), params: {
        care_record: {
          record_type: "weight",
          recorded_at: Time.current,
          weight_attributes: { weight: "4.2" },
          files: [file]
        }
      }
    end

    assert_redirected_to pet_path(pets(:one))
    assert_equal "対応していないファイル形式があったため、一部のファイルはアップロードされませんでした", flash[:alert]
  end

  test "update redirects to the pet page" do
    sign_in users(:one)
    record = pets(:one).care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    record.create_weight!(weight: 4.0)

    patch pet_care_record_path(pets(:one), record), params: {
      care_record: { weight_attributes: { id: record.weight.id, weight: "4.5" } }
    }

    assert_redirected_to pet_path(pets(:one))
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
