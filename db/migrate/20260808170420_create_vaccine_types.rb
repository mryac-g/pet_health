class CreateVaccineTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :vaccine_types, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false

      t.timestamps
    end

    add_index :vaccine_types, %i[user_id name], unique: true
  end
end
