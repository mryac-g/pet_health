class AddOriginalFilenameToAttachments < ActiveRecord::Migration[7.1]
  def change
    add_column :attachments, :original_filename, :string, null: false, default: ""
  end
end
