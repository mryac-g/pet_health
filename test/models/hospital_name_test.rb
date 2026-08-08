require "test_helper"

class HospitalNameTest < ActiveSupport::TestCase
  test "invalid without name" do
    hospital_name = HospitalName.new(user: users(:one), name: nil)
    assert_not hospital_name.valid?
  end

  test "invalid with a duplicate name for the same user" do
    hospital_name = HospitalName.new(user: users(:one), name: hospital_names(:one).name)
    assert_not hospital_name.valid?
  end

  test "valid with the same name for a different user" do
    hospital_name = HospitalName.new(user: users(:two), name: hospital_names(:one).name)
    assert hospital_name.valid?
  end
end
