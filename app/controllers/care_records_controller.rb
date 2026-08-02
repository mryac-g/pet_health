class CareRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet

  def new
    @care_record = @pet.care_records.new(record_type: :meal, recorded_at: Time.current)
    build_detail_associations
  end

  def create
    @care_record = @pet.care_records.new(care_record_params)

    if @care_record.save
      redirect_to root_path, notice: "ケア記録を登録しました"
    else
      build_detail_associations
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def build_detail_associations
    @care_record.meal || @care_record.build_meal
    @care_record.weight || @care_record.build_weight
    @care_record.temperature || @care_record.build_temperature
    @care_record.medication || @care_record.build_medication
    @care_record.walk || @care_record.build_walk
    @care_record.hospital_visit || @care_record.build_hospital_visit
  end

  def care_record_params
    params.require(:care_record).permit(
      :record_type, :recorded_at, :note,
      meal_attributes: %i[amount completion_rate],
      weight_attributes: %i[weight],
      temperature_attributes: %i[temperature],
      medication_attributes: %i[medicine_name dosage],
      walk_attributes: %i[duration_minutes distance],
      hospital_visit_attributes: %i[hospital_name diagnosis]
    )
  end
end
