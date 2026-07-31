class CreateTemperatures < ActiveRecord::Migration[7.1]
  def change
    create_table :temperatures, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.decimal :temperature, null: false
      t.datetime :created_at, null: false
    end
  end
end
