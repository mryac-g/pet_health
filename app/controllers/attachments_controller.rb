class AttachmentsController < ApplicationController
  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic application/pdf].freeze

  before_action :authenticate_user!
  before_action :set_pet_and_care_record

  def create
    file = params.dig(:attachment, :file)

    if file.blank?
      return redirect_to pet_care_record_path(@pet, @care_record), alert: "ファイルを選択してください"
    end

    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      return redirect_to pet_care_record_path(@pet, @care_record), alert: "対応していないファイル形式です"
    end

    if file.size > MAX_FILE_SIZE
      return redirect_to pet_care_record_path(@pet, @care_record), alert: "ファイルサイズは10MB以内にしてください"
    end

    key = "care_records/#{@care_record.id}/#{SecureRandom.uuid}-#{file.original_filename}"
    SupabaseStorage.client.put_object(
      bucket: SupabaseStorage.bucket,
      key: key,
      body: file.read,
      content_type: file.content_type
    )

    @care_record.attachments.create!(file_url: SupabaseStorage.public_url(key), file_type: file.content_type)
    redirect_to pet_care_record_path(@pet, @care_record), notice: "ファイルをアップロードしました"
  rescue => e
    Rails.logger.error("Supabase Storage upload failed: #{e.class}: #{e.message}")
    redirect_to pet_care_record_path(@pet, @care_record), alert: "アップロードに失敗しました"
  end

  private

  def set_pet_and_care_record
    @pet = current_user.pets.find(params[:pet_id])
    @care_record = @pet.care_records.find(params[:care_record_id])
  end
end
