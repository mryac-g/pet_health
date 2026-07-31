class CreateWalks < ActiveRecord::Migration[7.1]
  def change
    create_table :walks, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.integer :duration_minutes
      t.decimal :distance
      t.datetime :created_at, null: false
    end
  end
end
