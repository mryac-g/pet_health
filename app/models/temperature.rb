class Temperature < ApplicationRecord
  belongs_to :care_record

  validates :temperature, presence: true
end
