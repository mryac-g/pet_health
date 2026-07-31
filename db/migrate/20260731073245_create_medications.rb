class CreateMedications < ActiveRecord::Migration[7.1]
  def change
    create_table :medications, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.string :medicine_name, null: false
      t.string :dosage
      t.datetime :created_at, null: false
    end
  end
end
