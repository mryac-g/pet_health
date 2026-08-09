class Attachment < ApplicationRecord
  class BlankFileError < StandardError; end
  class UnsupportedContentTypeError < StandardError; end
  class FileTooLargeError < StandardError; end

  MAX_FILE_SIZE = 10.megabytes
  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg image/png image/webp image/heic
    video/mp4 video/quicktime
    application/pdf
    application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
  ].freeze

  belongs_to :care_record

  validates :storage_key, presence: true
  validates :file_type, presence: true
  validates :original_filename, presence: true

  def self.upload!(care_record:, file:)
    raise BlankFileError if file.blank?
    raise UnsupportedContentTypeError unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
    raise FileTooLargeError if file.size > MAX_FILE_SIZE

    key = storage_key_for(care_record, file)
    SupabaseStorage.upload(key: key, file: file)

    care_record.attachments.create!(storage_key: key, file_type: file.content_type, original_filename: file.original_filename)
  end

  # 保存キーは日本語等を含むファイル名によるS3側のエラーを避けるため、拡張子のみを残した安全な形にする
  def self.storage_key_for(care_record, file)
    "care_records/#{care_record.id}/#{SecureRandom.uuid}#{File.extname(file.original_filename)}"
  end

  def download_url
    SupabaseStorage.presigned_url(storage_key)
  end

  def destroy_with_storage!
    begin
      SupabaseStorage.delete(key: storage_key)
    rescue => e
      Rails.logger.error("Supabase Storage delete failed: #{e.class}: #{e.message}")
    end

    destroy!
  end
end
