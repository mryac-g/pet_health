class AddIconStorageKeyToPets < ActiveRecord::Migration[7.1]
  def change
    add_column :pets, :icon_storage_key, :string
  end
end
