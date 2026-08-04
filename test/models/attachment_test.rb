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
end
