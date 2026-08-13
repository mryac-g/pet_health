class Weight < ApplicationRecord
  include NumericField

  belongs_to :care_record

  validates :weight, presence: true
  normalizes_numeric_field :weight
end
