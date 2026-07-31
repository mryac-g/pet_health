class CreateAttachments < ActiveRecord::Migration[7.1]
  def change
    create_table :attachments, id: :uuid do |t|
      t.references :care_record, null: false, foreign_key: true, type: :uuid
      t.string :file_url, null: false
      t.string :file_type, null: false
      t.datetime :created_at, null: false
    end
  end
end
