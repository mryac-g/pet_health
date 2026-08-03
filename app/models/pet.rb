class Pet < ApplicationRecord
  belongs_to :user

  has_many :care_records, dependent: :destroy

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  SPECIES_LABELS = { "dog" => "犬", "cat" => "猫", "rabbit" => "うさぎ", "bird" => "鳥", "other" => "その他" }.freeze

  validates :name, presence: true

  def weight_series
    care_records.weight.includes(:weight).order(:recorded_at).filter_map do |care_record|
      next unless care_record.weight

      { date: care_record.recorded_at.strftime("%m/%d"), value: care_record.weight.weight.to_f }
    end
  end

  def meal_series
    care_records.meal.includes(:meal).order(:recorded_at).filter_map do |care_record|
      next unless care_record.meal

      { date: care_record.recorded_at.strftime("%m/%d"), value: care_record.meal.amount.to_f }
    end
  end
end
