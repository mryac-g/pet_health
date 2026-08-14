class PetRecordType < ApplicationRecord
  belongs_to :pet

  enum record_type: CareRecord.record_types

  validates :record_type, presence: true, uniqueness: { scope: :pet_id }
end
