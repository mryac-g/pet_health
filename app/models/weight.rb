class Weight < ApplicationRecord
  belongs_to :care_record

  validates :weight, presence: true
end
