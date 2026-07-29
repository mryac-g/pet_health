class Pet < ApplicationRecord
  belongs_to :user

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  validates :name, presence: true
end
