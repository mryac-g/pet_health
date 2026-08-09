class RenameFileUrlToStorageKeyOnAttachments < ActiveRecord::Migration[7.1]
  def change
    rename_column :attachments, :file_url, :storage_key
  end
end
