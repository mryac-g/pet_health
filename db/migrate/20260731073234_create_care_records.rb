class CreateCareRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :care_records, id: :uuid do |t|
      t.references :pet, null: false, foreign_key: true, type: :uuid
      t.integer :record_type, null: false
      t.datetime :recorded_at, null: false
      t.text :note

      t.timestamps
    end
  end
end
