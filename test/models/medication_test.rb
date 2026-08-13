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

  test "invalid when dosage_amount contains non-numeric characters" do
    medication = Medication.new(care_record: care_records(:one), medicine_name: "薬A", dosage_amount: "2錠")
    assert_not medication.valid?
    assert_includes medication.errors[:dosage_amount], "は数字のみで入力してください"
  end
end
