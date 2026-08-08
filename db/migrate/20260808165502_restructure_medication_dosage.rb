class RestructureMedicationDosage < ActiveRecord::Migration[7.1]
  def change
    add_column :medications, :dosage_amount, :decimal
    add_column :medications, :dosage_unit, :string
    remove_column :medications, :dosage, :string
  end
end
