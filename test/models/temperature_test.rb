require "test_helper"

class TemperatureTest < ActiveSupport::TestCase
  test "invalid without temperature" do
    temperature = Temperature.new(care_record: care_records(:one), temperature: nil)
    assert_not temperature.valid?
  end

  test "valid with temperature" do
    temperature = Temperature.new(care_record: care_records(:one), temperature: 38.5)
    assert temperature.valid?
  end

  test "normalizes zenkaku digits when setting temperature" do
    temperature = Temperature.new(care_record: care_records(:one), temperature: "３８．５")
    assert_equal BigDecimal("38.5"), temperature.temperature
  end

  test "invalid when temperature contains non-numeric characters" do
    temperature = Temperature.new(care_record: care_records(:one), temperature: "38.5度")
    assert_not temperature.valid?
    assert_includes temperature.errors[:temperature], "は数字のみで入力してください"
  end
end
