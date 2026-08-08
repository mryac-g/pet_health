class HospitalNamesController < ApplicationController
  include PresetListActions

  private

  def preset_scope
    current_user.hospital_names
  end

  def preset_index_path
    hospital_names_path
  end

  def preset_label
    "病院名"
  end

  def preset_param_key
    :hospital_name
  end
end
