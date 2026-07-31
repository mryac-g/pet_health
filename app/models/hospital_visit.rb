class HospitalVisit < ApplicationRecord
  belongs_to :care_record

  validates :hospital_name, presence: true
end
