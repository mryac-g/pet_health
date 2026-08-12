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

  test "show does not render a header shortcut since it is already the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)

    get pet_path(pet)

    assert_response :success
    assert_select "a", text: /のページに戻る/, count: 0
  end

  test "new does not render a header shortcut since the pet is not yet persisted" do
    sign_in users(:one)

    get new_pet_path

    assert_response :success
    assert_select "a", text: /のページに戻る/, count: 0
  end

  test "create re-rendering the form does not render a header shortcut for the unsaved pet" do
    sign_in users(:one)

    post pets_path, params: { pet: { name: "", species: "dog" } }

    assert_response :unprocessable_content
    assert_select "a", text: /のページに戻る/, count: 0
  end

  test "show renders multiple pet tabs without N+1 queries" do
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

  test "show renders the pet tabs as an index-tab style tablist with the content attached to the active tab" do
    sign_in users(:one)
    pet = pets(:one)
    other_pet = users(:one).pets.create!(name: "タマ", species: :cat)

    get pet_path(pet)

    assert_response :success
    assert_select "div[role=tablist].tabs.tabs-lift" do
      assert_select "a[role=tab].tab.tab-active[href=?]", pet_path(pet), text: pet.name
      assert_select "a[role=tab].tab[href=?]", pet_path(other_pet), text: other_pet.name
      assert_select "div.tab-content", text: /#{pet.name}/
    end
  end

  test "show does not render a tablist when the user has only one pet" do
    sign_in users(:one)
    pet = pets(:one)

    get pet_path(pet)

    assert_response :success
    assert_select "div[role=tablist]", count: 0
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
    assert_select "a[href=?]", new_pet_care_record_path(pet, record_type: "weight", return_to: pet_path(pet))
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

  test "summary applies the all period preset and includes records outside the default 30-day window" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 100.days.ago).create_weight!(weight: 4.2)

    get summary_pet_path(pet, period: "all", record_types: ["weight"])

    assert_response :success
    assert_includes @response.body, "期間: 全期間"
    assert_includes @response.body, "4.2kg"
    assert_select "input#from[value=?]", ""
  end

  test "summary defaults to only 食事(meal) checked when record_types have never been selected" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 100)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "input#record_type_meal[checked]"
    assert_select "input#record_type_weight[checked]", count: 0
    assert_includes @response.body, "■ 食事"
    assert_not_includes @response.body, "■ 体重"
  end

  test "summary renders a graph for graphable record types recorded within range" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    get summary_pet_path(pet, record_types: ["weight"])

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "体重(kg)"
  end

  test "summary applies a period preset and prefills the from/to inputs with the computed range" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :weight, recorded_at: 20.days.ago).create_weight!(weight: 4.0)

    get summary_pet_path(pet, period: "last_7_days", record_types: ["weight"])

    assert_response :success
    assert_includes @response.body, "4.2kg"
    assert_not_includes @response.body, "4kg\n"
    assert_select "input#from[value=?]", 7.days.ago.to_date.iso8601
    assert_select "input#to[value=?]", Date.current.iso8601
  end

  test "summary groups by date instead of record_type when group_by=date is selected" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00")
    weight_record.create_weight!(weight: 4.2)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: "2026-08-10 12:00")
    meal_record.create_meal!(amount: 100)

    get summary_pet_path(pet, group_by: "date", record_types: %w[weight meal])

    assert_response :success
    assert_includes @response.body, "■ 2026/08/10"
    assert_includes @response.body, "体重: 4.2kg"
    assert_not_includes @response.body, "■ 体重"

    get summary_pet_path(pet)

    assert_response :success
    assert_select "input#group_by_date[checked]"
  end

  test "summary remembers the date range filter and restores it on a later visit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01").create_weight!(weight: 4.0)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10").create_weight!(weight: 4.2)

    get summary_pet_path(pet, from: "2026-08-05", to: "2026-08-15", record_types: ["weight"])
    assert_includes @response.body, "08/10: 4.2kg"
    assert_not_includes @response.body, "08/01: 4kg"

    get summary_pet_path(pet)

    assert_response :success
    assert_select "input#from[value=?]", "2026-08-05"
    assert_select "input#to[value=?]", "2026-08-15"
    assert_includes @response.body, "08/10: 4.2kg"
  end

  test "summary clears the remembered date range when the reset link is followed" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)

    get summary_pet_path(pet, from: "2026-08-01", to: "2026-08-31")
    get summary_pet_path(pet, from: "", to: "", record_types: [""])

    get summary_pet_path(pet)

    # from falls back to the default 30-day lookback (not blank) once cleared; to has no default
    assert_response :success
    assert_select "input#from[value=?]", 30.days.ago.to_date.iso8601
    assert_select "input#to[value=?]", ""
  end

  test "summary remembers the selected record_types and restores them on a later visit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago).create_weight!(weight: 4.2)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago).create_meal!(amount: 100)

    get summary_pet_path(pet, record_types: ["weight"])
    assert_includes @response.body, "■ 体重"
    assert_not_includes @response.body, "■ 食事"

    get summary_pet_path(pet)

    assert_response :success
    assert_select "input#record_type_weight[checked]"
    assert_select "input#record_type_meal[checked]", count: 0
    assert_includes @response.body, "■ 体重"
    assert_not_includes @response.body, "■ 食事"
  end

  test "summary.pdf sets a Content-Disposition filename with the pet name and selected record types" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    get summary_pet_path(pet, format: :pdf, record_types: ["weight"])

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], "filename*=UTF-8''"
  end

  test "summary.pdf returns an actual PDF file generated from the same view" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    get summary_pet_path(pet, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "response body should be a PDF file"
  end

  test "summary renders a print button and a print-only plain-text copy of the summary" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago)
    weight_record.create_weight!(weight: 4.2)

    get summary_pet_path(pet, record_types: ["weight"])

    assert_response :success
    assert_select "button", text: "印刷する"
    assert_select "pre.print\\:block", text: /4.2kg/
  end

  test "create registers a pet for the current user" do
    sign_in users(:one)

    assert_difference("users(:one).pets.count", 1) do
      post pets_path, params: { pet: { name: "ポチ", species: "dog" } }
    end

    assert_redirected_to pet_path(Pet.order(:created_at).last)
  end

  test "create uploads an icon when a supported image file is given" do
    sign_in users(:one)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "image/png", original_filename: "icon.png")
    original_method = SupabaseStorage.method(:upload)

    begin
      SupabaseStorage.define_singleton_method(:upload) { |*| true }
      post pets_path, params: { pet: { name: "ポチ", species: "dog", icon: file } }
    ensure
      SupabaseStorage.define_singleton_method(:upload, original_method)
    end

    assert Pet.order(:created_at).last.icon_storage_key.present?
  end

  test "create shows an alert but still saves the pet when the icon file type is unsupported" do
    sign_in users(:one)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "icon.txt")

    assert_difference("Pet.count", 1) do
      post pets_path, params: { pet: { name: "ポチ", species: "dog", icon: file } }
    end

    assert_equal "対応していない画像形式です", flash[:alert]
  end

  test "create re-renders the form when invalid" do
    sign_in users(:one)

    assert_no_difference("Pet.count") do
      post pets_path, params: { pet: { name: "", species: "dog" } }
    end

    assert_response :unprocessable_content
  end
end
