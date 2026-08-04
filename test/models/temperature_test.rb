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
end
