require "test_helper"

class AttachmentTest < ActiveSupport::TestCase
  test "invalid without file_url or file_type" do
    attachment = Attachment.new(care_record: care_records(:one), file_url: nil, file_type: nil)
    assert_not attachment.valid?
  end

  test "valid with file_url and file_type" do
    attachment = Attachment.new(
      care_record: care_records(:one),
      file_url: "https://example.com/x.png",
      file_type: "image/png"
    )
    assert attachment.valid?
  end

  test "upload! raises BlankFileError when file is blank" do
    assert_raises(Attachment::BlankFileError) do
      Attachment.upload!(care_record: care_records(:one), file: nil)
    end
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

  test "destroy_with_storage! removes the record even when the storage delete fails" do
    attachment = attachments(:one)

    assert_difference("Attachment.count", -1) do
      attachment.destroy_with_storage!
    end
  end
end
