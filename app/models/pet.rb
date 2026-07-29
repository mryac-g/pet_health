class Pet < ApplicationRecord
  belongs_to :user

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  SPECIES_LABELS = { "dog" => "犬", "cat" => "猫", "rabbit" => "うさぎ", "bird" => "鳥", "other" => "その他" }.freeze

  validates :name, presence: true
end
