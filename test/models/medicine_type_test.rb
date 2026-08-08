require "test_helper"

class MedicineTypeTest < ActiveSupport::TestCase
  test "invalid without name" do
    medicine_type = MedicineType.new(user: users(:one), name: nil)
    assert_not medicine_type.valid?
  end

  test "invalid with a duplicate name for the same user" do
    medicine_type = MedicineType.new(user: users(:one), name: medicine_types(:one).name)
    assert_not medicine_type.valid?
  end

  test "valid with the same name for a different user" do
    medicine_type = MedicineType.new(user: users(:two), name: medicine_types(:one).name)
    assert medicine_type.valid?
  end
end
