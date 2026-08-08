class CareRecordsController < ApplicationController
  DETAIL_ATTRIBUTES = {
    meal_attributes: %i[food_name unit amount completion_rate],
    water_attributes: %i[amount],
    weight_attributes: %i[weight],
    temperature_attributes: %i[temperature],
    medication_attributes: %i[medicine_name dosage_amount dosage_unit],
    toilet_attributes: %i[kind condition],
    walk_attributes: %i[duration_minutes distance],
    hospital_visit_attributes: %i[hospital_name vaccine_type diagnosis],
    care_attributes: %i[care_type]
  }.freeze

  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_care_record, only: %i[show edit update destroy]
  before_action :set_meal_presets, only: %i[new create edit update]
  before_action :set_medicine_types, only: %i[new create edit update]
  before_action :set_hospital_visit_presets, only: %i[new create edit update]

  def index
    @care_records = @pet.care_records
                         .includes(*CareRecord::DETAIL_ASSOCIATIONS)
                         .order(recorded_at: :desc)
  end

  def show
  end

  def new
    @care_record = @pet.care_records.new(record_type: :meal, recorded_at: Time.current.change(sec: 0))
    @care_record.build_missing_details
    prefill_last_meal_choices
    prefill_last_medication_choices
  end

  def create
    @care_record = @pet.care_records.new(care_record_params)

    if @care_record.save
      redirect_to root_path, notice: "ケア記録を登録しました", alert: upload_attachments
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
      redirect_to root_path, notice: "ケア記録を更新しました", alert: upload_attachments
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

  def set_meal_presets
    @meal_types = current_user.meal_types.order(:name)
    @meal_units = current_user.meal_units.order(:name)
  end

  def set_medicine_types
    @medicine_types = current_user.medicine_types.order(:name)
  end

  def set_hospital_visit_presets
    @hospital_names = current_user.hospital_names.order(:name)
    @vaccine_types = current_user.vaccine_types.order(:name)
  end

  # ペットごとに、前回記録した食事の種類・単位をあらかじめ選択された状態にする
  def prefill_last_meal_choices
    last_meal = @pet.last_meal
    return unless last_meal

    @care_record.meal.food_name ||= last_meal.food_name
    @care_record.meal.unit ||= last_meal.unit
  end

  # ペットごとに、前回記録した薬の種類・容量の単位をあらかじめ選択された状態にする
  def prefill_last_medication_choices
    last_medication = @pet.last_medication
    return unless last_medication

    @care_record.medication.medicine_name ||= last_medication.medicine_name
    @care_record.medication.dosage_unit ||= last_medication.dosage_unit
  end

  # フォームで選択された添付ファイルをアップロードする。失敗しても記録自体は保存済みのため、
  # エラーメッセージを返すのみで記録の保存処理には影響させない
  def upload_attachments
    attachment_files.each { |file| Attachment.upload!(care_record: @care_record, file: file) }
    nil
  rescue Attachment::UnsupportedContentTypeError
    "対応していないファイル形式があったため、一部のファイルはアップロードされませんでした"
  rescue Attachment::FileTooLargeError
    "ファイルサイズが10MBを超えるものがあったため、一部のファイルはアップロードされませんでした"
  rescue => e
    Rails.logger.error("Supabase Storage upload failed: #{e.class}: #{e.message}")
    "ファイルのアップロードに失敗しました"
  end

  def attachment_files
    Array(params.dig(:care_record, :files)).reject(&:blank?)
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
