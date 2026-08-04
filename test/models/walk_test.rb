require "test_helper"

class WalkTest < ActiveSupport::TestCase
  test "valid without duration_minutes or distance" do
    walk = Walk.new(care_record: care_records(:one))
    assert walk.valid?
  end
end
