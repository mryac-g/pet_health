class VaccineTypesController < ApplicationController
  include PresetListActions

  private

  def preset_scope
    current_user.vaccine_types
  end

  def preset_index_path
    vaccine_types_path
  end

  def preset_label
    "ワクチンの種類"
  end

  def preset_param_key
    :vaccine_type
  end
end
