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

  test "show renders species and birthday next to the icon, with the birthday in slash format" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(species: :cat, birthday: Date.new(2019, 7, 7))

    get pet_path(pet)

    assert_response :success
    assert_includes @response.body, "2019/07/07"
    assert_not_includes @response.body, "2019-07-07"
  end

  test "show renders welcomed_on next to the icon when present" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(welcomed_on: Date.new(2022, 4, 1))

    get pet_path(pet)

    assert_response :success
    assert_includes @response.body, "お迎えした日: 2022/04/01"
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
      weight_record = pet.care_records.create!(record_type: :weight, recorded_at: i.days.ago, weight_attributes: { weight: 4.0 + i })
      meal_record = pet.care_records.create!(record_type: :meal, recorded_at: i.days.ago, meal_attributes: { amount: 100 + i, completion_rate: 90 })
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

  test "show renders a desktop-only pet switcher in the sidebar when there are multiple pets" do
    sign_in users(:one)
    pet = pets(:one)
    other_pet = users(:one).pets.create!(name: "タマ", species: :cat)

    get pet_path(pet)

    assert_response :success
    assert_select "aside nav a.font-bold[href=?]", pet_path(pet), text: pet.name
    assert_select "aside nav a[href=?]", pet_path(other_pet), text: other_pet.name
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
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

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

  test "show only renders cards for the pet's enabled record types" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(record_type_keys: %w[meal weight])

    get pet_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "meal")
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "weight")
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "walk"), count: 0
  end

  test "patching only record_type_keys leaves other attributes untouched" do
    sign_in users(:one)
    pet = pets(:one)
    original_name = pet.name

    patch pet_path(pet), params: { pet: { record_type_keys: %w[meal] } }

    pet.reload
    assert_equal %w[meal], pet.record_type_keys
    assert_equal original_name, pet.name
  end

  test "summary renders multiple record types without N+1 queries" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })
    hospital_record = pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current, hospital_visit_attributes: { hospital_name: "元気動物病院" })

    get summary_pet_path(pet)

    assert_response :success
  end

  test "summary applies the all period preset and includes records outside the default 30-day window" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 100.days.ago, weight_attributes: { weight: 4.2 })

    get summary_pet_path(pet, period: "all", record_types: ["weight"])

    assert_response :success
    assert_includes @response.body, "期間: 全期間"
    assert_includes @response.body, "4.2kg"
    assert_select "input#from[value=?]", ""
  end

  test "summary remembers the all period preset on a later visit that sends no params (e.g. the PDF download link)" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 100.days.ago, weight_attributes: { weight: 4.2 })

    get summary_pet_path(pet, period: "all", record_types: ["weight"])
    assert_includes @response.body, "4.2kg"

    get summary_pet_path(pet)

    assert_response :success
    assert_includes @response.body, "期間: 全期間"
    assert_includes @response.body, "4.2kg"
  end

  test "summary's period preset select shows the currently active preset as selected, even after a later visit that sends no period param" do
    sign_in users(:one)
    pet = pets(:one)

    get summary_pet_path(pet, period: "all")
    assert_select "select#period option[selected][value=?]", "all"

    get summary_pet_path(pet)

    assert_response :success
    assert_select "select#period option[selected][value=?]", "all"
  end

  test "summary defaults to only 食事(meal) checked when record_types have never been selected" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100 })

    get summary_pet_path(pet)

    assert_response :success
    assert_select "input#record_type_meal[checked]"
    assert_select "input#record_type_weight[checked]", count: 0
    assert_includes @response.body, "■ 食事"
    assert_not_includes @response.body, "■ 体重"
  end

  test "summary renders a unit dropdown for meal when the pet has records in more than one unit, and filtering by it excludes the other unit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { food_name: "フードA", amount: 100, unit: "g" })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "フードB", amount: 2, unit: "袋" })

    get summary_pet_path(pet, record_types: ["meal"])
    assert_select "select#meal_unit" do
      assert_select "option[value=g]"
      assert_select "option[value=?]", "袋"
    end
    assert_includes @response.body, "フードA"
    assert_includes @response.body, "フードB"

    get summary_pet_path(pet, record_types: ["meal"], meal_unit: "g")
    assert_includes @response.body, "フードA"
    assert_not_includes @response.body, "フードB"
  end

  test "summary renders the completion-rate checkbox only when a meal with a completion_rate exists in range and meal is selected" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100, completion_rate: 50 })

    get summary_pet_path(pet, period: "all", record_types: ["meal"])
    assert_select "input#reflect_meal_completion_rate", count: 1

    get summary_pet_path(pet, period: "all", record_types: ["weight"])
    assert_select "input#reflect_meal_completion_rate", count: 0
  end

  test "summary does not render the completion-rate checkbox when no meal has a completion_rate" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100 })

    get summary_pet_path(pet, period: "all", record_types: ["meal"])

    assert_select "input#reflect_meal_completion_rate", count: 0
  end

  test "summary shows the completion-rate-adjusted amount and graph label when the checkbox is checked" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100, completion_rate: 50 })

    get summary_pet_path(pet, period: "all", record_types: ["meal"], reflect_meal_completion_rate: "1")

    assert_response :success
    assert_includes @response.body, "100.0g(200.0g)"
    assert_select "canvas[data-line-chart-label-value=?]", "食事量(完食率換算)"
  end

  test "summary does not render a unit dropdown when the pet has no meal or medication records yet" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "select#meal_unit", count: 0
    assert_select "select#medication_unit", count: 0
  end

  test "summary remembers the meal_unit filter on a later visit that sends no params" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { food_name: "フードA", amount: 100, unit: "g" })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "フードB", amount: 2, unit: "袋" })

    get summary_pet_path(pet, record_types: ["meal"], meal_unit: "g")
    assert_not_includes @response.body, "フードB"

    get summary_pet_path(pet)

    assert_response :success
    assert_not_includes @response.body, "フードB"
  end

  test "summary renders a graph for graphable record types recorded within range" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get summary_pet_path(pet, record_types: ["weight"])

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "体重"
  end

  test "summary applies a period preset and prefills the from/to inputs with the computed range" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago, weight_attributes: { weight: 4.2 })
    pet.care_records.create!(record_type: :weight, recorded_at: 20.days.ago, weight_attributes: { weight: 4.0 })

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
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00", weight_attributes: { weight: 4.2 })
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: "2026-08-10 12:00", meal_attributes: { amount: 100 })

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
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10", weight_attributes: { weight: 4.2 })

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
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

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
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 100 })

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
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get summary_pet_path(pet, format: :pdf, record_types: ["weight"])

    assert_response :success
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], "filename*=UTF-8''"
  end

  test "summary.pdf returns an actual PDF file generated from the same view" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get summary_pet_path(pet, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "response body should be a PDF file"
  end

  test "summary renders an 編集する button next to each line of the summary text, linking to that record's edit page" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "テストフード", amount: 80 })

    get summary_pet_path(pet, record_types: ["meal"])

    assert_response :success
    edit_link = css_select("a").find { |a| a.text == "編集する" }
    assert_equal edit_pet_care_record_path(pet, meal_record), URI(edit_link["href"]).path
    return_to = Rack::Utils.parse_nested_query(URI(edit_link["href"]).query)["return_to"]
    assert_equal "/pets/#{pet.id}/summary", URI(return_to).path
    return_to_params = Rack::Utils.parse_nested_query(URI(return_to).query)
    assert_equal ["meal"], return_to_params["record_types"]
    assert_equal "care_record_#{meal_record.id}", return_to_params["scroll_to"]
    assert_select "li#care_record_#{meal_record.id}", text: /テストフード/
    assert_includes @response.body, "テストフード"
  end

  test "summary scrolls to the record named by scroll_to (e.g. after returning from the 編集する button)" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "テストフード", amount: 80 })

    get summary_pet_path(pet, record_types: ["meal"], scroll_to: "care_record_#{meal_record.id}")

    assert_response :success
    assert_select "div[data-controller=?][data-scroll-into-view-target-value=?]",
      "clipboard print scroll-into-view summary-view-toggle", "care_record_#{meal_record.id}"
  end

  test "summary has no scroll target when arriving without scroll_to" do
    sign_in users(:one)
    pet = pets(:one)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "div[data-scroll-into-view-target-value=?]", ""
  end

  test "summary renders the PDF download link with data-turbo=false so Turbo Drive doesn't intercept the download" do
    sign_in users(:one)
    pet = pets(:one)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "a[href=?][data-turbo=?]", summary_pet_path(pet, format: :pdf), "false"
  end

  test "summary's 編集する button carries the current summary URL as return_to, so the edit page can send the user back to it" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "テストフード", amount: 80 })

    get summary_pet_path(pet, record_types: ["meal"])
    edit_link = css_select("a").find { |a| a.text == "編集する" }
    return_to = Rack::Utils.parse_nested_query(URI(edit_link["href"]).query)["return_to"]

    get URI(edit_link["href"]).path, params: { return_to: return_to }
    assert_select "a[href=?]", return_to, text: "← #{pet.name}のページに戻る"

    patch pet_care_record_path(pet, meal_record), params: { care_record: { recorded_at: meal_record.recorded_at }, return_to: return_to }
    assert_redirected_to return_to
  end

  test "summary renders the record-type headers as plain text, not links" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 80 })

    get summary_pet_path(pet, record_types: ["meal"])

    assert_response :success
    assert_select "a", text: "■ 食事", count: 0
    assert_includes @response.body, "■ 食事"
  end

  test "summary keeps the 編集する buttons out of the copy source and the print/PDF output" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 80 })

    get summary_pet_path(pet, record_types: ["meal"])

    assert_response :success
    assert_not_includes css_select("textarea[data-clipboard-target=source]").first.text, "編集する"
    assert_not_includes css_select("pre").first.text, "編集する"
  end

  test "summary renders buttons to toggle between showing text only, graph only, or both" do
    sign_in users(:one)
    pet = pets(:one)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "button[data-action=?][data-mode=text]", "summary-view-toggle#showText"
    assert_select "button[data-action=?][data-mode=graph]", "summary-view-toggle#showGraph"
    assert_select "button[data-action=?][data-mode=both].btn-active", "summary-view-toggle#showBoth"
    assert_select "div[data-summary-view-toggle-target=text]"
    assert_select "div[data-summary-view-toggle-target=graph]"
  end

  test "summary renders a header shortcut back to the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)

    get summary_pet_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_path(pet), text: /#{pet.name}のページに戻る/
  end

  test "summary renders a print button and a print-only plain-text copy of the summary" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

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

  test "create's success notice renders inside a fixed toast so it doesn't shift the page layout" do
    sign_in users(:one)

    post pets_path, params: { pet: { name: "ポチ", species: "dog" } }
    follow_redirect!

    assert_response :success
    assert_select ".toast[data-controller=flash] div[role=alert]", text: "ポチを登録しました"
  end

  test "new renders a checkbox for every record type, all checked by default" do
    sign_in users(:one)

    get new_pet_path

    assert_response :success
    CareRecord::RECORD_TYPE_LABELS.each_key do |record_type|
      assert_select "input#pet_record_type_keys_#{record_type}[checked]"
    end
  end

  test "create only enables the checked record types" do
    sign_in users(:one)

    post pets_path, params: { pet: { name: "ポチ", species: "dog", record_type_keys: %w[meal weight] } }

    assert_equal %w[meal weight], Pet.order(:created_at).last.record_type_keys
  end

  test "create re-renders the form with an error when no record types are checked" do
    sign_in users(:one)

    assert_no_difference("Pet.count") do
      post pets_path, params: { pet: { name: "ポチ", species: "dog", record_type_keys: [""] } }
    end

    assert_response :unprocessable_content
    assert_select "div[role=alert]", text: /を1つ以上選択してください/
  end

  test "edit renders a header shortcut back to the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)

    get edit_pet_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_path(pet), text: /#{pet.name}のページに戻る/
  end

  test "edit preselects the pet's currently enabled record types" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(record_type_keys: %w[meal weight])

    get edit_pet_path(pet)

    assert_response :success
    assert_select "input#pet_record_type_keys_meal[checked]"
    assert_select "input#pet_record_type_keys_weight[checked]"
    assert_select "input#pet_record_type_keys_walk[checked]", count: 0
  end

  test "update changes which record types are enabled" do
    sign_in users(:one)
    pet = pets(:one)

    patch pet_path(pet), params: { pet: { record_type_keys: %w[meal] } }

    assert_equal %w[meal], pet.reload.record_type_keys
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
