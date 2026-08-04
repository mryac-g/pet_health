require "test_helper"

class MedicationTest < ActiveSupport::TestCase
  test "invalid without medicine_name" do
    medication = Medication.new(care_record: care_records(:one), medicine_name: nil)
    assert_not medication.valid?
  end

  test "valid with medicine_name" do
    medication = Medication.new(care_record: care_records(:one), medicine_name: "薬A")
    assert medication.valid?
  end
end
