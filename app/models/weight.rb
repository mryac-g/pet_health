class Weight < ApplicationRecord
  include NumericField

  UNITS = %w[kg g].freeze

  belongs_to :care_record

  validates :weight, presence: true
  validates :unit, inclusion: { in: UNITS }
  normalizes_numeric_field :weight
end
