require "test_helper"

class VaccineTypeTest < ActiveSupport::TestCase
  test "invalid without name" do
    vaccine_type = VaccineType.new(user: users(:one), name: nil)
    assert_not vaccine_type.valid?
  end

  test "invalid with a duplicate name for the same user" do
    vaccine_type = VaccineType.new(user: users(:one), name: vaccine_types(:one).name)
    assert_not vaccine_type.valid?
  end

  test "valid with the same name for a different user" do
    vaccine_type = VaccineType.new(user: users(:two), name: vaccine_types(:one).name)
    assert vaccine_type.valid?
  end
end
