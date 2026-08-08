class CreateHospitalNames < ActiveRecord::Migration[7.1]
  def change
    create_table :hospital_names, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false

      t.timestamps
    end

    add_index :hospital_names, %i[user_id name], unique: true
  end
end
