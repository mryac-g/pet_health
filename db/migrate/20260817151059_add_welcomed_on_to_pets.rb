class AddWelcomedOnToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :welcomed_on, :date
  end
end
