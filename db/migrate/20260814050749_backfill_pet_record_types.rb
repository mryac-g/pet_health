class BackfillPetRecordTypes < ActiveRecord::Migration[7.1]
  def up
    Pet.find_each do |pet|
      CareRecord::RECORD_TYPE_LABELS.each_key { |type| pet.pet_record_types.find_or_create_by!(record_type: type) }
    end
  end

  def down
    PetRecordType.delete_all
  end
end
