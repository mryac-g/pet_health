require "test_helper"

class AttachmentTest < ActiveSupport::TestCase
  test "invalid without storage_key or file_type" do
    attachment = Attachment.new(care_record: care_records(:one), storage_key: nil, file_type: nil)
    assert_not attachment.valid?
  end

  test "valid with storage_key and file_type" do
    attachment = Attachment.new(
      care_record: care_records(:one),
      storage_key: "care_records/one/uuid-x.png",
      file_type: "image/png"
    )
    assert attachment.valid?
  end

  test "upload! raises BlankFileError when file is blank" do
    assert_raises(Attachment::BlankFileError) do
      Attachment.upload!(care_record: care_records(:one), file: nil)
    end
  end

  test "allows video and office document content types" do
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "video/mp4"
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "video/quicktime"
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "application/msword"
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "application/vnd.ms-excel"
    assert_includes Attachment::ALLOWED_CONTENT_TYPES, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
  end

  test "upload! raises UnsupportedContentTypeError for disallowed content types" do
    file = Rack::Test::UploadedFile.new(StringIO.new("hello"), "text/plain", original_filename: "test.txt")

    assert_raises(Attachment::UnsupportedContentTypeError) do
      Attachment.upload!(care_record: care_records(:one), file: file)
    end
  end

  test "upload! raises FileTooLargeError for oversized files" do
    oversized_content = "a" * (Attachment::MAX_FILE_SIZE + 1)
    file = Rack::Test::UploadedFile.new(StringIO.new(oversized_content), "image/png", original_filename: "test.png")

    assert_raises(Attachment::FileTooLargeError) do
      Attachment.upload!(care_record: care_records(:one), file: file)
    end
  end

  test "original_filename strips the uuid prefix from the storage key" do
    attachment = Attachment.new(storage_key: "care_records/one/#{SecureRandom.uuid}-my photo.png")
    assert_equal "my photo.png", attachment.original_filename
  end

  test "destroy_with_storage! removes the record even when the storage delete fails" do
    attachment = attachments(:one)

    assert_difference("Attachment.count", -1) do
      attachment.destroy_with_storage!
    end
  end
end
