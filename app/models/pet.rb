class Pet < ApplicationRecord
  class UnsupportedIconContentTypeError < StandardError; end
  class IconTooLargeError < StandardError; end

  MAX_ICON_SIZE = 5.megabytes
  ALLOWED_ICON_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic].freeze

  belongs_to :user

  has_many :care_records, dependent: :destroy

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  SPECIES_LABELS = { "dog" => "犬", "cat" => "猫", "rabbit" => "うさぎ", "bird" => "鳥", "other" => "その他" }.freeze

  validates :name, presence: true

  # icon_storage_key(アップロードされたアイコン画像)があれば署名付きURLを、
  # 無ければ従来の icon_url(手入力の画像URL)をそのまま使う
  def icon_download_url
    return SupabaseStorage.presigned_url(icon_storage_key) if icon_storage_key.present?

    icon_url.presence
  end

  def upload_icon!(file)
    return if file.blank?
    raise UnsupportedIconContentTypeError unless ALLOWED_ICON_CONTENT_TYPES.include?(file.content_type)
    raise IconTooLargeError if file.size > MAX_ICON_SIZE

    key = "pets/#{id}/#{SecureRandom.uuid}#{File.extname(file.original_filename)}"
    SupabaseStorage.upload(key: key, file: file)
    update!(icon_storage_key: key)
  end

  def last_meal
    Meal.joins(:care_record).where(care_records: { pet_id: id }).order(created_at: :desc).first
  end

  def last_medication
    Medication.joins(:care_record).where(care_records: { pet_id: id }).order(created_at: :desc).first
  end

  def latest_care_records_by_type
    care_records
      .includes(*CareRecord::DETAIL_ASSOCIATIONS)
      .order(recorded_at: :desc)
      .group_by(&:record_type)
      .transform_values(&:first)
  end

  def summary_text(since: 30.days.ago)
    records = care_records
              .includes(:meal, :weight, :temperature, :medication, :walk, :hospital_visit)
              .where(recorded_at: since..)
              .order(:recorded_at)

    lines = []
    lines << "【#{name}のケア記録サマリー】"
    lines << "期間: #{since.to_date.strftime('%Y/%m/%d')} 〜 #{Date.current.strftime('%Y/%m/%d')}"

    if records.empty?
      lines << ""
      lines << "該当期間の記録はありません。"
      return lines.join("\n")
    end

    grouped = records.group_by(&:record_type)

    CareRecord::RECORD_TYPE_LABELS.each do |record_type, label|
      group = grouped[record_type]
      next if group.blank?

      lines << ""
      lines << "■ #{label}"
      group.each do |care_record|
        date = care_record.recorded_at.strftime("%m/%d")
        detail = care_record.detail_summary
        text = detail ? "#{date}: #{detail}" : date
        text += "(#{care_record.note})" if care_record.note.present?
        lines << text
      end
    end

    lines.join("\n")
  end
end
