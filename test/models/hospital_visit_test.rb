require "test_helper"

class HospitalVisitTest < ActiveSupport::TestCase
  test "invalid without hospital_name" do
    hospital_visit = HospitalVisit.new(care_record: care_records(:one), hospital_name: nil)
    assert_not hospital_visit.valid?
  end

  test "valid with hospital_name" do
    hospital_visit = HospitalVisit.new(care_record: care_records(:one), hospital_name: "元気動物病院")
    assert hospital_visit.valid?
  end
end
