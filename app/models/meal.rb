class Meal < ApplicationRecord
  belongs_to :care_record

  validates :amount, presence: true
end
