require "test_helper"

class InquiryTest < ActiveSupport::TestCase
  test "valid with name, email and message" do
    inquiry = Inquiry.new(user: users(:one), name: "一郎", email: "one@example.com", message: "質問があります")

    assert inquiry.valid?
  end

  test "invalid without message" do
    inquiry = Inquiry.new(user: users(:one), name: "一郎", email: "one@example.com", message: "")

    assert_not inquiry.valid?
  end

  test "invalid with a malformed email" do
    inquiry = Inquiry.new(user: users(:one), name: "一郎", email: "not-an-email", message: "質問があります")

    assert_not inquiry.valid?
  end
end
