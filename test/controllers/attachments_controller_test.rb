require "test_helper"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  test "show redirects unauthenticated users to sign in" do
    get pet_care_record_attachment_path(pets(:one), care_records(:one), attachments(:one))

    assert_redirected_to new_user_session_path
  end

  test "show redirects the owner to a presigned download url" do
    sign_in users(:one)
    original_method = SupabaseStorage.method(:presigned_url)

    begin
      SupabaseStorage.define_singleton_method(:presigned_url) { |*| "https://example.com/signed-url" }
      get pet_care_record_attachment_path(pets(:one), care_records(:one), attachments(:one))
    ensure
      SupabaseStorage.define_singleton_method(:presigned_url, original_method)
    end

    assert_redirected_to "https://example.com/signed-url"
  end

  test "show is rejected for another user's attachment" do
    sign_in users(:two)

    get pet_care_record_attachment_path(pets(:one), care_records(:one), attachments(:one))

    assert_response :not_found
  end

  test "create redirects unauthenticated users to sign in" do
    post pet_care_record_attachments_path(pets(:one), care_records(:one))

    assert_redirected_to new_user_session_path
  end

  test "create shows an alert when no file is given" do
    sign_in users(:one)

    post pet_care_record_attachments_path(pets(:one), care_records(:one))

    assert_redirected_to pet_care_record_path(pets(:one), care_records(:one))
    assert_equal "ファイルを選択してください", flash[:alert]
  end

  test "create rejects unsupported content types" do
    sign_in users(:one)
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "test.txt")

    assert_no_difference("Attachment.count") do
      post pet_care_record_attachments_path(pets(:one), care_records(:one)), params: { attachment: { file: file } }
    end

    assert_equal "対応していないファイル形式です", flash[:alert]
  end

  test "create is rejected for another user's care_record" do
    sign_in users(:two)

    post pet_care_record_attachments_path(pets(:one), care_records(:one))

    assert_response :not_found
  end

  test "destroy removes the attachment for the owner" do
    sign_in users(:one)

    assert_difference("Attachment.count", -1) do
      delete pet_care_record_attachment_path(pets(:one), care_records(:one), attachments(:one))
    end

    assert_redirected_to pet_care_record_path(pets(:one), care_records(:one))
  end

  test "destroy is rejected for another user's attachment" do
    sign_in users(:two)

    assert_no_difference("Attachment.count") do
      delete pet_care_record_attachment_path(pets(:one), care_records(:one), attachments(:one))
    end

    assert_response :not_found
  end
end
