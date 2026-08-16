class AddUserToInquiries < ActiveRecord::Migration[7.1]
  def change
    add_reference :inquiries, :user, null: false, foreign_key: true, type: :uuid
  end
end
