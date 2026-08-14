class Medication < ApplicationRecord
  include NumericField

  belongs_to :care_record

  DOSAGE_UNITS = %w[錠 個 ml cc mg g 包 滴].freeze

  validates :medicine_name, presence: true
  normalizes_numeric_field :dosage_amount
end
