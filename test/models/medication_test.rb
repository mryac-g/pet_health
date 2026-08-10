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

  test "normalizes zenkaku digits when setting dosage_amount" do
    medication = Medication.new(care_record: care_records(:one), dosage_amount: "２")
    assert_equal BigDecimal("2"), medication.dosage_amount
  end
end
