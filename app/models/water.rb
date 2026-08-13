class Water < ApplicationRecord
  include NumericField

  belongs_to :care_record

  validates :amount, presence: true
  normalizes_numeric_field :amount
end
