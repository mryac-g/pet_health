require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "index is accessible without authentication" do
    get root_path

    assert_response :success
  end

  test "signed-out title tag and navbar show the renamed brand うちの子ログ" do
    get root_path

    assert_response :success
    assert_select "title", text: "うちの子ログ"
    assert_select "img[alt=?]", "うちの子ログ"
  end

  test "signed-in sidebar shows the renamed brand うちの子ログ" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "aside span", text: "うちの子ログ"
  end

  test "index renders links to account registration and sign in, not just the guest button" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", new_user_registration_path, text: "アカウント登録"
    assert_select "a[href=?]", new_user_session_path, text: "ログイン"
  end

  test "signed-out layout does not force md:flex on body, since the navbar (unlike the signed-in sidebar) has no width cap and would collapse the page to 0 width" do
    get root_path

    assert_response :success
    assert_select "body:not(.md\\:flex)"
  end

  test "signed-in layout keeps md:flex on body so the sidebar and main content sit side by side" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "body.md\\:flex"
  end

  test "index lists the current user's pets when signed in" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "body", text: /#{pets(:one).name}/
  end

  test "header does not show a pet page shortcut since no pet is in context" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "a", text: /のページに戻る/, count: 0
  end

  test "index renders multiple pets without N+1 queries" do
    sign_in users(:one)
    users(:one).pets.create!(name: "タマ", species: :cat)
    users(:one).pets.create!(name: "ハチ", species: :dog)

    get root_path

    assert_response :success
  end

  test "index renders a card grid with a dashed add-pet card and the sidebar's home link" do
    sign_in users(:one)

    get root_path

    assert_response :success
    assert_select "a[href=?]", pet_path(pets(:one)), text: /#{pets(:one).name}/
    assert_select "a[href=?]", new_pet_path, text: /新しい家族を追加/
    assert_select "aside nav a[href=?]", root_path, text: "ホーム"
  end

  test "index renders the pet switcher in the sidebar too, so the sidebar stays consistent across pages" do
    sign_in users(:one)
    other_pet = users(:one).pets.create!(name: "タマ", species: :cat)

    get root_path

    assert_response :success
    assert_select "aside nav a[href=?]", pet_path(pets(:one)), text: pets(:one).name
    assert_select "aside nav a[href=?]", pet_path(other_pet), text: other_pet.name
  end

  test "index greets guest users as ゲスト instead of showing the auto-generated email" do
    post guest_sign_in_path

    get root_path

    assert_response :success
    assert_includes @response.body, "ゲスト"
    assert_not_includes @response.body, "@example.com"
  end
end
