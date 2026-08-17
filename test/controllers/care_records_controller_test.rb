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
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "体重"
    assert_select ".stat-title", count: 0
    assert_select "ul li", count: 0
  end

  test "graph renders one canvas per numeric field for record types with multiple graphable fields" do
    sign_in users(:one)
    pet = pets(:one)
    walk = pet.care_records.create!(record_type: :walk, recorded_at: 1.day.ago, walk_attributes: { duration_minutes: 30, distance: 2.5 })

    get graph_pet_care_records_path(pet, record_type: "walk")

    assert_response :success
    assert_select "canvas[data-line-chart-label-value=?]", "散歩時間(分)"
    assert_select "canvas[data-line-chart-label-value=?]", "散歩距離(km)"
  end

  test "graph splits into multiple canvases once a series exceeds the max points per graph, evenly rather than leaving a tiny leftover graph" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    (CareRecord::MAX_POINTS_PER_GRAPH + 3).times do |i|
      pet.care_records.create!(record_type: :weight, recorded_at: i.days.ago, weight_attributes: { weight: 4.0 })
    end

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    canvases = css_select('canvas[data-line-chart-label-value="体重"]')
    assert_equal 2, canvases.size
    # 18件を上限15で区切ると15件+3件になり最後だけ極端に少なくなるため、9件+9件に均等分割する
    assert_equal 9, JSON.parse(canvases.first["data-line-chart-data-value"]).size
    assert_equal 9, JSON.parse(canvases[1]["data-line-chart-data-value"]).size
    assert_select "h2", text: /体重の推移\s*\(1\/2\)/
    assert_select "h2", text: /体重の推移\s*\(2\/2\)/
  end

  test "graph does not add a (1/1) suffix when a series fits in a single graph" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    graph_heading = css_select("h2").find { |h2| h2.text.include?("の推移") }
    assert_equal "体重の推移", graph_heading.text.strip
  end

  test "graph respects the persisted date range filter for that pet and record_type" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00", weight_attributes: { weight: 4.1 })

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04")
    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    points = JSON.parse(css_select("canvas").first["data-line-chart-data-value"])
    assert_equal [4.1], points.map { |p| p["y"] }
  end

  test "graph plots points by actual recorded time, not by record index, so same-day records cluster and gaps stay visible" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 21:00", weight_attributes: { weight: 4.05 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00", weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    points = JSON.parse(css_select("canvas").first["data-line-chart-data-value"])
    x_values = points.map { |p| p["x"] }
    same_day_gap = x_values[1] - x_values[0]
    nine_days_later_gap = x_values[2] - x_values[1]

    assert_equal 3, x_values.size
    assert_operator nine_days_later_gap, :>, same_day_gap * 10
  end

  test "graph points carry the recorded date/time and note for the tooltip" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    record = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-09 13:45", note: "検診のついでに", weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    point = JSON.parse(css_select("canvas").first["data-line-chart-data-value"]).first
    assert_equal "2026/08/09 13:45", point["recorded_at"]
    assert_equal "検診のついでに", point["note"]
  end

  test "graph points have a nil note when the record has none" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-09 13:45", weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    point = JSON.parse(css_select("canvas").first["data-line-chart-data-value"]).first
    assert_nil point["note"]
  end

  test "graph includes a link back to the full record list" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get graph_pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "weight"), text: "記録一覧を見る"
  end

  test "show does not render a graph shortcut" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_record_path(pet, weight_record)

    assert_response :success
    assert_select "a", text: "グラフを見る", count: 0
  end

  test "show renders the meal's own unit instead of a hardcoded g" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { amount: 2, unit: "袋" })

    get pet_care_record_path(pet, meal_record)

    assert_response :success
    assert_select "dd", text: "2.0袋"
    assert_select "dd", text: "2.0g", count: 0
  end

  test "show links back to the filtered list for that record's own type, not the unfiltered list" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_record_path(pet, weight_record)

    assert_response :success
    assert_select "a[href=?]", pet_care_records_path(pet, record_type: "weight"), text: "一覧に戻る"
  end

  test "index renders a header shortcut back to the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)

    get pet_care_records_path(pet)

    assert_response :success
    assert_select "a[href=?]", pet_path(pet), text: "← #{pet.name}のページに戻る"
  end

  test "show renders a header shortcut back to the pet's own page" do
    sign_in users(:one)
    pet = pets(:one)
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_record_path(pet, weight_record)

    assert_response :success
    assert_select "a[href=?]", pet_path(pet), text: "← #{pet.name}のページに戻る"
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
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { amount: 100, completion_rate: 90 })
    weight_record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })
    hospital_record = pet.care_records.create!(record_type: :hospital_visit, recorded_at: Time.current, hospital_visit_attributes: { hospital_name: "元気動物病院" })

    get pet_care_records_path(pet)

    assert_response :success
  end

  test "index filters records by record_type when given" do
    sign_in users(:one)
    pet = pets(:one)
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { amount: 100, completion_rate: 90 })
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "h1", text: "体重の記録一覧"
    assert_select "li", count: pet.care_records.weight.count
    assert_select "a[href=?]", new_pet_care_record_path(pet, record_type: "weight", return_to: pet_care_records_path(pet, record_type: "weight")), text: "＋"
  end

  test "index leads each row with the date and omits the year for records from this year" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "#{Date.current.year}-08-05 09:33", weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "li a" do
      assert_select "div", text: "8/5"
      assert_select "div", text: "09:33"
      assert_select "div", text: "#{Date.current.year}年", count: 0
    end
  end

  test "index shows the year for records from a previous year" do
    sign_in users(:one)
    pet = pets(:one)
    last_year = Date.current.year - 1
    pet.care_records.create!(record_type: :weight, recorded_at: "#{last_year}-12-31 07:36", weight_attributes: { weight: 4.0 })

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "li a" do
      assert_select "div", text: "#{last_year}年"
      assert_select "div", text: "12/31"
    end
  end

  test "index still renders the pet switcher in the sidebar (not just on the pet's own page)" do
    sign_in users(:one)
    pet = pets(:one)
    other_pet = users(:one).pets.create!(name: "タマ", species: :cat)

    get pet_care_records_path(pet)

    assert_response :success
    assert_select "aside nav a[href=?]", pet_path(pet), text: pet.name
    assert_select "aside nav a[href=?]", pet_path(other_pet), text: other_pet.name
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
    meal_record = pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { amount: 100, completion_rate: 90 })
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "not_a_real_type")

    assert_response :success
    assert_select "h1", text: "全記録一覧"
    assert_select "li", count: pet.care_records.count
  end

  test "index applies a period preset and prefills the from/to inputs with the computed range" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago, weight_attributes: { weight: 4.2 })
    pet.care_records.create!(record_type: :weight, recorded_at: 20.days.ago, weight_attributes: { weight: 4.0 })

    get pet_care_records_path(pet, record_type: "weight", period: "last_7_days")

    assert_response :success
    assert_select "li", count: 1
    assert_select "input#from[value=?]", 7.days.ago.to_date.iso8601
    assert_select "input#to[value=?]", Date.current.iso8601
  end

  test "index remembers the period preset's computed range across a later plain visit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 3.days.ago, weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight", period: "last_7_days")
    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "input#from[value=?]", 7.days.ago.to_date.iso8601
  end

  test "index filters records by date range when from and to are given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    in_range = pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00", weight_attributes: { weight: 4.1 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00", weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04", to: "2026-08-06")

    assert_response :success
    assert_select "li", count: 1
  end

  test "index filters records from the given date onward when only from is given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00", weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-05")

    assert_response :success
    assert_select "li", count: 1
  end

  test "index renders a unit dropdown for meal when the pet has records in more than one unit, and filtering by it excludes the other unit and recalculates the total" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { food_name: "フードA", amount: 100, unit: "g" })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "フードB", amount: 2, unit: "袋" })

    get pet_care_records_path(pet, record_type: "meal")
    assert_select "select#unit" do
      assert_select "option[value=g]"
      assert_select "option[value=?]", "袋"
    end
    assert_includes @response.body, "フードA"
    assert_includes @response.body, "フードB"
    assert_select ".stat-value", text: "2"

    get pet_care_records_path(pet, record_type: "meal", unit: "g")
    assert_includes @response.body, "フードA"
    assert_not_includes @response.body, "フードB"
    assert_select ".stat-value", text: "1"
  end

  test "index does not render a unit dropdown when the pet has no meal records yet" do
    sign_in users(:one)
    pet = users(:one).pets.create!(name: "ポチ", species: :dog)

    get pet_care_records_path(pet, record_type: "meal")

    assert_response :success
    assert_select "select#unit", count: 0
  end

  test "index remembers the unit filter on a later visit that sends no unit param" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :meal, recorded_at: 2.days.ago, meal_attributes: { food_name: "フードA", amount: 100, unit: "g" })
    pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "フードB", amount: 2, unit: "袋" })

    get pet_care_records_path(pet, record_type: "meal", unit: "g")
    assert_not_includes @response.body, "フードB"

    get pet_care_records_path(pet, record_type: "meal")

    assert_response :success
    assert_not_includes @response.body, "フードB"
  end

  test "index filters medication records by dosage_unit independently from meal's unit filter" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :medication, recorded_at: 2.days.ago, medication_attributes: { medicine_name: "薬A", dosage_amount: 1, dosage_unit: "錠" })
    pet.care_records.create!(record_type: :medication, recorded_at: 1.day.ago, medication_attributes: { medicine_name: "薬B", dosage_amount: 5, dosage_unit: "ml" })

    get pet_care_records_path(pet, record_type: "medication", unit: "錠")

    assert_response :success
    assert_includes @response.body, "薬A"
    assert_not_includes @response.body, "薬B"
  end

  test "index filters records up to the given date when only to is given" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-10 09:00", weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet, record_type: "weight", to: "2026-08-05")

    assert_response :success
    # care_records(:one) fixture (2026-07-31) also falls within the "to" range
    assert_select "li", count: 2
  end

  test "index ignores invalid from/to date params" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })

    get pet_care_records_path(pet, record_type: "weight", from: "not-a-date", to: "also-not-a-date")

    assert_response :success
    assert_select "li", count: pet.care_records.weight.count
  end

  test "index remembers the date range filter and restores it on a later visit without params" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00", weight_attributes: { weight: 4.1 })

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
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00", weight_attributes: { weight: 4.1 })
    pet.care_records.create!(record_type: :meal, recorded_at: "2026-05-05 09:00", meal_attributes: { amount: 100 })

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
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-01", to: "2026-08-31")
    get pet_care_records_path(pet, record_type: "weight", from: "", to: "")

    get pet_care_records_path(pet, record_type: "weight")

    assert_response :success
    assert_select "input#from[value=?]", ""
    assert_select "input#to[value=?]", ""
    assert_select "li", count: pet.care_records.weight.count
  end

  test "index renders a グラフを見る button (not an inline canvas) when record_type has a numeric field" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-01 09:00", weight_attributes: { weight: 4.0 })
    pet.care_records.create!(record_type: :weight, recorded_at: "2026-08-05 09:00", weight_attributes: { weight: 4.1 })

    get pet_care_records_path(pet, record_type: "weight", from: "2026-08-04")

    assert_response :success
    assert_select "a[href=?]", graph_pet_care_records_path(pet, record_type: "weight"), text: "グラフを見る"
    assert_select "canvas", count: 0
  end

  test "index shows one stats block per numeric field for record types with multiple graphable fields" do
    sign_in users(:one)
    pet = pets(:one)
    walk = pet.care_records.create!(record_type: :walk, recorded_at: 1.day.ago, walk_attributes: { duration_minutes: 30, distance: 2.5 })

    get pet_care_records_path(pet, record_type: "walk")

    assert_response :success
    assert_select ".stat-title", text: "記録回数", count: 2
    assert_select ".stat-title", text: "散歩時間(分)合計"
    assert_select ".stat-title", text: "散歩距離(km)合計"
  end

  test "index renders count/sum/average stats even though the graph itself is behind a popup" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :water, recorded_at: 2.days.ago, water_attributes: { amount: 100 })
    pet.care_records.create!(record_type: :water, recorded_at: 1.day.ago, water_attributes: { amount: 200 })

    get pet_care_records_path(pet, record_type: "water")

    assert_response :success
    assert_select ".stat-title", text: "記録回数"
    assert_select ".stat-value", text: "2"
    assert_select ".stat-title", text: "水の量(ml)合計"
    assert_select ".stat-value", text: "300.0"
    assert_select ".stat-title", text: "水の量(ml)平均"
    assert_select ".stat-value", text: "150.0"
  end

  test "index does not render a graph button for record types without a numeric field" do
    sign_in users(:one)
    pet = pets(:one)
    toilet = pet.care_records.create!(record_type: :toilet, recorded_at: 1.day.ago, toilet_attributes: { kind: "pee" })

    get pet_care_records_path(pet, record_type: "toilet")

    assert_response :success
    assert_select "a", text: "グラフを見る", count: 0
  end

  test "index does not render a graph button when not filtered by record_type" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.2 })

    get pet_care_records_path(pet)

    assert_response :success
    assert_select "a", text: "グラフを見る", count: 0
  end

  test "new preselects the record_type given in params" do
    sign_in users(:one)

    get new_pet_care_record_path(pets(:one), record_type: "water")

    assert_response :success
    assert_select "h1", text: "水の記録を登録"
    assert_select "input[name=?]", "care_record[water_attributes][amount]"
  end

  test "new falls back to meal for an invalid record_type param" do
    sign_in users(:one)

    get new_pet_care_record_path(pets(:one), record_type: "not_a_real_type")

    assert_response :success
    assert_select "h1", text: "食事の記録を登録"
    assert_select "input[name=?]", "care_record[meal_attributes][amount]"
  end

  test "new redirects with an alert when the record_type is valid globally but disabled for the pet" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(record_type_keys: %w[meal])

    get new_pet_care_record_path(pet, record_type: "weight")

    assert_redirected_to pet_path(pet)
    assert_equal "体重はこのペットでは記録できません", flash[:alert]
  end

  test "new falls back to the pet's own first enabled type, not a hardcoded meal, when meal is disabled" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(record_type_keys: %w[weight walk])

    get new_pet_care_record_path(pet)

    assert_response :success
    assert_select "h1", text: "体重の記録を登録"
  end

  test "create is rejected with an alert for a record_type disabled on the pet" do
    sign_in users(:one)
    pet = pets(:one)
    pet.update!(record_type_keys: %w[meal])

    assert_no_difference("CareRecord.count") do
      post pet_care_records_path(pet), params: {
        care_record: { record_type: "weight", recorded_at: Time.current, weight_attributes: { weight: 4.2 } }
      }
    end

    assert_redirected_to pet_path(pet)
    assert_equal "体重はこのペットでは記録できません", flash[:alert]
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
    record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "ドライフードA", unit: "g", amount: 100 })

    get new_pet_care_record_path(pet)

    assert_response :success
    assert_select "input#care_record_meal_attributes_food_name[value=?]", "ドライフードA"
    assert_select "input#care_record_meal_attributes_unit[value=?]", "g"
  end

  test "new prefills the meal form with the pet's last used unit even when it differs from the default g" do
    sign_in users(:one)
    pet = pets(:one)
    record = pet.care_records.create!(record_type: :meal, recorded_at: 1.day.ago, meal_attributes: { food_name: "カリカリ", unit: "袋", amount: 1 })

    get new_pet_care_record_path(pet)

    assert_response :success
    assert_select "input#care_record_meal_attributes_unit[value=?]", "袋"
  end

  test "new prefills the weight form with the pet's last used unit" do
    sign_in users(:one)
    pet = pets(:one)
    pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 85, unit: "g" })

    get new_pet_care_record_path(pet, record_type: "weight")

    assert_response :success
    assert_select "select#care_record_weight_attributes_unit option[selected][value=g]"
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

    assert_redirected_to pet_care_records_path(pets(:one), record_type: "weight")
    assert_equal 4.2, CareRecord.order(:created_at).last.weight.weight.to_f
  end

  test "create redirects to the record's own type list with a message naming the record type" do
    sign_in users(:one)

    post pet_care_records_path(pets(:one)), params: {
      care_record: {
        record_type: "weight",
        recorded_at: Time.current,
        weight_attributes: { weight: "4.2" }
      }
    }

    assert_redirected_to pet_care_records_path(pets(:one), record_type: "weight")
    assert_equal "体重を登録しました", flash[:notice]
  end

  test "new renders a hidden return_to field only when the param is a safe local path" do
    sign_in users(:one)
    pet = pets(:one)

    get new_pet_care_record_path(pet, record_type: "weight", return_to: pet_path(pet))
    assert_select "input[type=hidden][name=return_to][value=?]", pet_path(pet)

    get new_pet_care_record_path(pet, record_type: "weight", return_to: "https://evil.example.com")
    assert_select "input[type=hidden][name=return_to]", count: 0
  end

  test "create redirects back to return_to (e.g. the pet page) when it was reached via the pet page's + button" do
    sign_in users(:one)
    pet = pets(:one)

    post pet_care_records_path(pet), params: {
      care_record: { record_type: "weight", recorded_at: Time.current, weight_attributes: { weight: "4.2" } },
      return_to: pet_path(pet)
    }

    assert_redirected_to pet_path(pet)
  end

  test "create ignores a return_to pointing off-site and falls back to the record type list" do
    sign_in users(:one)
    pet = pets(:one)

    post pet_care_records_path(pet), params: {
      care_record: { record_type: "weight", recorded_at: Time.current, weight_attributes: { weight: "4.2" } },
      return_to: "https://evil.example.com"
    }

    assert_redirected_to pet_care_records_path(pet, record_type: "weight")
  end

  test "edit renders a hidden return_to field, and the header shortcut points there instead of the pet page" do
    sign_in users(:one)
    pet = pets(:one)
    record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.0 })

    get edit_pet_care_record_path(pet, record, return_to: summary_pet_path(pet))

    assert_select "input[type=hidden][name=return_to][value=?]", summary_pet_path(pet)
    assert_select "a[href=?]", summary_pet_path(pet), text: "← #{pet.name}のページに戻る"
  end

  test "update redirects back to return_to (e.g. the summary page) when it was reached from there" do
    sign_in users(:one)
    pet = pets(:one)
    record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.0 })

    patch pet_care_record_path(pet, record), params: {
      care_record: { weight_attributes: { id: record.weight.id, weight: "4.5" } },
      return_to: summary_pet_path(pet)
    }

    assert_redirected_to summary_pet_path(pet)
  end

  test "update ignores a return_to pointing off-site and falls back to the record type list" do
    sign_in users(:one)
    pet = pets(:one)
    record = pet.care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.0 })

    patch pet_care_record_path(pet, record), params: {
      care_record: { weight_attributes: { id: record.weight.id, weight: "4.5" } },
      return_to: "https://evil.example.com"
    }

    assert_redirected_to pet_care_records_path(pet, record_type: "weight")
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

    assert_redirected_to pet_care_records_path(pets(:one), record_type: "weight")
    assert_equal "対応していないファイル形式があったため、一部のファイルはアップロードされませんでした", flash[:alert]
  end

  test "update redirects to the record's own type list with a message naming the record type" do
    sign_in users(:one)
    record = pets(:one).care_records.create!(record_type: :weight, recorded_at: 1.day.ago, weight_attributes: { weight: 4.0 })

    patch pet_care_record_path(pets(:one), record), params: {
      care_record: { weight_attributes: { id: record.weight.id, weight: "4.5" } }
    }

    assert_redirected_to pet_care_records_path(pets(:one), record_type: "weight")
    assert_equal "体重を更新しました", flash[:notice]
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
