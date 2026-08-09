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

  def self.upload!(care_record:, file:)
    raise BlankFileError if file.blank?
    raise UnsupportedContentTypeError unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
    raise FileTooLargeError if file.size > MAX_FILE_SIZE

    key = "care_records/#{care_record.id}/#{SecureRandom.uuid}-#{file.original_filename}"
    SupabaseStorage.client.put_object(
      bucket: SupabaseStorage.bucket,
      key: key,
      body: file.read,
      content_type: file.content_type
    )

    care_record.attachments.create!(storage_key: key, file_type: file.content_type)
  end

  def download_url
    SupabaseStorage.presigned_url(storage_key)
  end

  def original_filename
    storage_key.split("/").last.sub(/\A[0-9a-f-]{36}-/, "")
  end

  def destroy_with_storage!
    begin
      SupabaseStorage.client.delete_object(bucket: SupabaseStorage.bucket, key: storage_key)
    rescue => e
      Rails.logger.error("Supabase Storage delete failed: #{e.class}: #{e.message}")
    end

    destroy!
  end
end
