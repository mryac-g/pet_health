class CreatePets < ActiveRecord::Migration[7.1]
  def change
    create_table :pets, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.integer :species, null: false, default: 0
      t.string :species_note
      t.date :birthday
      t.string :icon_url

      t.timestamps
    end
  end
end
