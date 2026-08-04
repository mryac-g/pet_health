require "test_helper"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
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
end
