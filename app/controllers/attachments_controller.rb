class AttachmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet_and_care_record
  before_action :set_attachment, only: :show

  # 直接ファイルURLへリダイレクトすると、ブラウザ標準の何もないファイル表示になり
  # 閉じる・戻る手段がないタブになってしまうため、簡易ヘッダー付きの表示画面を挟む
  def show
  end

  def create
    Attachment.upload!(care_record: @care_record, file: params.dig(:attachment, :file))
    redirect_to pet_care_record_path(@pet, @care_record), notice: "ファイルをアップロードしました"
  rescue Attachment::BlankFileError
    redirect_to pet_care_record_path(@pet, @care_record), alert: "ファイルを選択してください"
  rescue Attachment::UnsupportedContentTypeError
    redirect_to pet_care_record_path(@pet, @care_record), alert: "対応していないファイル形式です"
  rescue Attachment::FileTooLargeError
    redirect_to pet_care_record_path(@pet, @care_record), alert: "ファイルサイズは10MB以内にしてください"
  rescue => e
    Rails.logger.error("Supabase Storage upload failed: #{e.class}: #{e.message}")
    redirect_to pet_care_record_path(@pet, @care_record), alert: "アップロードに失敗しました"
  end

  def destroy
    @care_record.attachments.find(params[:id]).destroy_with_storage!
    redirect_to pet_care_record_path(@pet, @care_record), notice: "ファイルを削除しました"
  end

  private

  def set_pet_and_care_record
    @pet = current_user.pets.find(params[:pet_id])
    @care_record = @pet.care_records.find(params[:care_record_id])
  end

  def set_attachment
    @attachment = @care_record.attachments.find(params[:id])
  end
end
