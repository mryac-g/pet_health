class AddUnitToMeals < ActiveRecord::Migration[7.1]
  def change
    add_column :meals, :unit, :string
  end
end
