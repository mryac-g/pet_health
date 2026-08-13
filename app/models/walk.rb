class Walk < ApplicationRecord
  include NumericField

  belongs_to :care_record

  normalizes_numeric_field :duration_minutes
  normalizes_numeric_field :distance
end
