class AddFoodNameToMeals < ActiveRecord::Migration[7.1]
  def change
    add_column :meals, :food_name, :string
  end
end
