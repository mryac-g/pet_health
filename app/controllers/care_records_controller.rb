class CareRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_care_record, only: %i[show edit update]

  def index
    @care_records = @pet.care_records
                         .includes(:meal, :weight, :temperature, :medication, :walk, :hospital_visit)
                         .order(recorded_at: :desc)
  end

  def show
  end

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

  def edit
    build_detail_associations
  end

  def update
    if @care_record.update(care_record_update_params)
      redirect_to root_path, notice: "ケア記録を更新しました"
    else
      build_detail_associations
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_care_record
    @care_record = @pet.care_records.find(params[:id])
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

  # record_typeは作成後に変更不可(詳細レコードの整合性が崩れるため)
  def care_record_update_params
    params.require(:care_record).permit(
      :recorded_at, :note,
      meal_attributes: %i[id amount completion_rate],
      weight_attributes: %i[id weight],
      temperature_attributes: %i[id temperature],
      medication_attributes: %i[id medicine_name dosage],
      walk_attributes: %i[id duration_minutes distance],
      hospital_visit_attributes: %i[id hospital_name diagnosis]
    )
  end
end
