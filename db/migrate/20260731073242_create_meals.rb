class CreateMeals < ActiveRecord::Migration[7.1]
  def change
    create_table :meals, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, null: false
      t.decimal :completion_rate
      t.datetime :created_at, null: false
    end
  end
end
