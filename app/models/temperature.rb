class Temperature < ApplicationRecord
  include NumericField

  belongs_to :care_record

  validates :temperature, presence: true
  normalizes_numeric_field :temperature
end
