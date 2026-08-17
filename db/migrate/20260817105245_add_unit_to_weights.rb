class AddUnitToWeights < ActiveRecord::Migration[7.1]
  def change
    # 既存の体重記録はすべてkg単位で入力されていたため、デフォルト値をkgにする
    add_column :weights, :unit, :string, default: "kg", null: false
  end
end
