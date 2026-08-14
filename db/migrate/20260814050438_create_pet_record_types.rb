class CreatePetRecordTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :pet_record_types, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :pet, null: false, foreign_key: true, type: :uuid
      t.integer :record_type, null: false

      t.timestamps
    end

    add_index :pet_record_types, %i[pet_id record_type], unique: true
  end
end
