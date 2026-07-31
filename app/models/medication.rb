class Medication < ApplicationRecord
  belongs_to :care_record

  validates :medicine_name, presence: true
end
