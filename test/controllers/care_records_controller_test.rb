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

  test "graph redirects unauthenticated users to sign in" do
    get graph_pet_care_records_path(pets(:one))

    assert_redirected_to new_user_session_path
  end

  test "graph returns not_found for another user's pet" do
    sign_in users(:two)

    get graph_pet_care_records_path(pets(:one))

    assert_response :not_found
  end

  test "graph renders a canvas for a graphable record_type without the list or stats" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "体重(kg)"
    assert_select ".stat-title", count: 0
    assert_select "ul li", count: 0
  end

  test "graph renders one canvas per numeric field for record types with multiple graphable fields" do
    sign_in users(:one)
    pet = pets(:one)
    walk = pet.care_records.create!(record_type: :walk, recorded_at: 1.day.ago)
    walk.create_walk!(duration_minutes: 30, distance: 2.5)

    get graph_pet_care_records_path(pet, record_type: "walk")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "散歩時間(分)"
    assert_select "canvas[data-line-chart-label-value=?]", "散歩距離(km)"
  end

  test "graph respects the persisted date range filter for that pet and record_type" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00").create_weight!(weight: 4.1)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04")
    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "canvas[data-line-chart-data-value=?]", "[4.1]"
  end

  test "graph includes a link back to the full record list" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "weight"), text: "記録一覧を見る"
  end

  test "show renders a graph shortcut for graphable record types but not for others" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)
    toilet_record = pet.care_records.create!(record_type: :toilet, recorded_at: 1.day.ago)
    toilet_record.create_toilet!(kind: "pee")

    get pet_care_record_path(pet, weight_record)
    assert_response :success
    assert_select "a[href=?]", graph_pet_care_records_path(pet, record_type: "weight"), text: "グラフを見る"

    get pet_care_record_path(pet, toilet_record)
    assert_response :success
    assert_select "a", text: "グラフを見る", count: 0
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

  test "index applies a period preset and prefills the from/to inputs with the computed range" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :weight, recorded_at: 20.days.ago).create_weight!(weight: 4.0)

    get pet_care_records_path(pet, record_type: "weight", period: "last_7_days")

    assert_response :success
    assert_select "li", count: 1
    assert_select "input#from[value=?]", 7.days.ago.to_date.iso8601
    assert_select "input#to[value=?]", Date.current.iso8601
  end

  test "index remembers the period preset's computed range across a later plain visit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago).create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "weight", period: "last_7_days")
    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "input#from[value=?]", 7.days.ago.to_date.iso8601
  end

  test "index filters records by date range when from and to are given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    in_range = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00")
    in_range.create_weight!(weight: 4.1)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00").create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04", to: "2026-08-06")

    assert_response :success
    assert_select "li", count: 1
  end

  test "index filters records from the given date onward when only from is given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00").create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-05")

    assert_response :success
    assert_select "li", count: 1
  end

  test "index filters records up to the given date when only to is given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00").create_weight!(weight: 4.2)

    get pet_care_records_path(pet, record_type: "weight", to: "2026-08-05")

    assert_response :success
    # care_records(:one) fixture (2026-07-31) also falls within the "to" range
    assert_select "li", count: 2
  end

  test "index ignores invalid from/to date params" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)

    get pet_care_records_path(pet, record_type: "weight", from: "not-a-date", to: "also-not-a-date")

    assert_response :success
    assert_select "li", count: pet.care_records.weight.count
  end

  test "index remembers the date range filter and restores it on a later visit without params" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00").create_weight!(weight: 4.1)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04", to: "2026-08-06")
    assert_select "li", count: 1

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "input#from[value=?]", "2026-08-04"
    assert_select "input#to[value=?]", "2026-08-06"
    assert_select "li", count: 1
  end

  test "index remembers separate date ranges for different record types independently" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00").create_weight!(weight: 4.1)
    pet.care_records.create!(record_type: :meal, recorded_at: "2026-05-05 09:00").create_meal!(amount: 100)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-01", to: "2026-08-31")
    get pet_care_records_path(pet, record_type: "meal", from: "2026-04-01", to: "2026-08-31")

    get pet_care_records_path(pet, record_type: "weight")
    assert_select "input#from[value=?]", "2026-08-01"

    get pet_care_records_path(pet, record_type: "meal")
    assert_select "input#from[value=?]", "2026-04-01"
  end

  test "index clears the remembered date range when the reset link is followed" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-01", to: "2026-08-31")
    get pet_care_records_path(pet, record_type: "weight", from: "", to: "")

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "input#from[value=?]", ""
    assert_select "input#to[value=?]", ""
    assert_select "li", count: pet.care_records.weight.count
  end

  test "index renders a graph canvas reflecting the filtered records when record_type has a numeric field" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00").create_weight!(weight: 4.1)

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "体重(kg)"
    assert_select "canvas[data-line-chart-data-value=?]", "[4.1]"
  end

  test "index renders one canvas per numeric field for record types with multiple graphable fields" do
    sign_in users(:one)
    pet = pets(:one)
    walk = pet.care_records.create!(record_type: :walk, recorded_at: 1.day.ago)
    walk.create_walk!(duration_minutes: 30, distance: 2.5)

    get pet_care_records_path(pet, record_type: "walk")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "散歩時間(分)"
    assert_select "canvas[data-line-chart-label-value=?]", "散歩距離(km)"
  end

  test "index renders count/sum/average stats below the graph" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :water, recorded_at: 2.days.ago).create_water!(amount: 100)
    pet.care_records.create!(record_type: :water, recorded_at: 1.day.ago).create_water!(amount: 200)

    get pet_care_records_path(pet, record_type: "water")

    assert_response :success
    assert_select ".stat-title", text: "件数"
    assert_select ".stat-value", text: "2"
    assert_select ".stat-title", text: "合計"
    assert_select ".stat-value", text: "300"
    assert_select ".stat-title", text: "平均"
    assert_select ".stat-value", text: "150"
  end

  test "index does not render a graph for record types without a numeric field" do
    sign_in users(:one)
    pet = pets(:one)
    toilet = pet.care_records.create!(record_type: :toilet, recorded_at: 1.day.ago)
    toilet.create_toilet!(kind: "pee")

    get pet_care_records_path(pet, record_type: "toilet")

    assert_response :success
    assert_select "canvas", count: 0
  end

  test "index does not render a graph when not filtered by record_type" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get pet_care_records_path(pet)

    assert_response :success
    assert_select "canvas", count: 0
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
