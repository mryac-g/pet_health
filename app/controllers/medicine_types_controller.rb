class MedicineTypesController < ApplicationController
  include PresetListActions

  private

  def preset_scope
    current_user.medicine_types
  end

  def preset_index_path
    medicine_types_path
  end

  def preset_label
    "薬の種類"
  end

  def preset_param_key
    :medicine_type
  end
end
