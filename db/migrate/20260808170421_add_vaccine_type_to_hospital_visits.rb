class AddVaccineTypeToHospitalVisits < ActiveRecord::Migration[7.1]
  def change
    add_column :hospital_visits, :vaccine_type, :string
  end
end
