class Attachment < ApplicationRecord
  belongs_to :care_record

  validates :file_url, presence: true
  validates :file_type, presence: true
end
