class CareRecordsController < ApplicationController
  DETAIL_ATTRIBUTES = {
    meal_attributes: %i[food_name amount completion_rate],
    weight_attributes: %i[weight],
    temperature_attributes: %i[temperature],
    medication_attributes: %i[medicine_name dosage],
    walk_attributes: %i[duration_minutes distance],
    hospital_visit_attributes: %i[hospital_name diagnosis]
  }.freeze

  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_care_record, only: %i[show edit update destroy]
  before_action :set_meal_types, only: %i[new create edit update]

  def index
    @care_records = @pet.care_records
                         .includes(*CareRecord::DETAIL_ASSOCIATIONS)
                         .order(recorded_at: :desc)
  end

  def show
  end

  def new
    @care_record = @pet.care_records.new(record_type: :meal, recorded_at: Time.current)
    @care_record.build_missing_details
  end

  def create
    @care_record = @pet.care_records.new(care_record_params)

    if @care_record.save
      redirect_to root_path, notice: "ケア記録を登録しました"
    else
      @care_record.build_missing_details
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @care_record.build_missing_details
  end

  def update
    if @care_record.update(care_record_update_params)
      redirect_to root_path, notice: "ケア記録を更新しました"
    else
      @care_record.build_missing_details
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @care_record.destroy
    redirect_to pet_care_records_path(@pet), notice: "ケア記録を削除しました"
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  def set_care_record
    @care_record = @pet.care_records.find(params[:id])
  end

  def set_meal_types
    @meal_types = current_user.meal_types.order(:name)
  end

  def care_record_params
    params.require(:care_record).permit(:record_type, :recorded_at, :note, **DETAIL_ATTRIBUTES)
  end

  # record_typeは作成後に変更不可(詳細レコードの整合性が崩れるため)
  def care_record_update_params
    detail_attributes_with_id = DETAIL_ATTRIBUTES.transform_values { |fields| [:id, *fields] }
    params.require(:care_record).permit(:recorded_at, :note, **detail_attributes_with_id)
  end
end
