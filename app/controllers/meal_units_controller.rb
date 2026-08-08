class MealUnitsController < ApplicationController
  include PresetListActions

  private

  def preset_scope
    current_user.meal_units
  end

  def preset_index_path
    meal_units_path
  end

  def preset_label
    "食事の単位"
  end

  def preset_param_key
    :meal_unit
  end
end
