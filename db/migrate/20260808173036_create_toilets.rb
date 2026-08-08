class CreateToilets < ActiveRecord::Migration[7.1]
  def change
    create_table :toilets, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.integer :kind, null: false
      t.integer :condition
      t.datetime :created_at, null: false
    end
  end
end
