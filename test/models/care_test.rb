require "test_helper"

class CareTest < ActiveSupport::TestCase
  test "invalid without care_type" do
    care = Care.new(care_record: care_records(:one), care_type: nil)
    assert_not care.valid?
  end

  test "valid with care_type" do
    care = Care.new(care_record: care_records(:one), care_type: :trimming)
    assert care.valid?
  end
end
