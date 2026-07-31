class CreateHospitalVisits < ActiveRecord::Migration[7.1]
  def change
    create_table :hospital_visits, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.string :hospital_name, null: false
      t.text :diagnosis
      t.datetime :created_at, null: false
    end
  end
end
