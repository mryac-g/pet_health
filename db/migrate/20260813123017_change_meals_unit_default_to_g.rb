class ChangeMealsUnitDefaultToG < ActiveRecord::Migration[7.1]
  def change
    change_column_default :meals, :unit, from: nil, to: "g"
  end
end
