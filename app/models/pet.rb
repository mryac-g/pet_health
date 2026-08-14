class Pet < ApplicationRecord
  class UnsupportedIconContentTypeError < StandardError; end
  class IconTooLargeError < StandardError; end

  MAX_ICON_SIZE = 5.megabytes
  ALLOWED_ICON_CONTENT_TYPES = %w[image/jpeg image/png image/webp image/heic].freeze

  belongs_to :user

  has_many :care_records, dependent: :destroy
  has_many :pet_record_types, dependent: :destroy, autosave: true

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  SPECIES_LABELS = { "dog" => "犬", "cat" => "猫", "rabbit" => "うさぎ", "bird" => "鳥", "other" => "その他" }.freeze

  validates :name, presence: true
  validate :record_type_keys_present

  after_initialize :seed_default_record_types, if: :new_record?

  # フォームのチェックボックス用。RECORD_TYPE_LABELSの宣言順で、有効な記録項目のキーを返す
  def record_type_keys
    CareRecord::RECORD_TYPE_LABELS.keys & pet_record_types.reject(&:marked_for_destruction?).map(&:record_type)
  end

  # 既存行を丸ごと置き換えるとpet.save前にDBへ即時反映されてしまうため、
  # build/mark_for_destructionで差分だけを積み、pet.saveのトランザクション内
  # (バリデーション通過後)に反映されるようにする
  def record_type_keys=(keys)
    @record_type_keys_assigned = true
    desired = CareRecord::RECORD_TYPE_LABELS.keys & Array(keys).map(&:to_s)
    current = pet_record_types.reject(&:marked_for_destruction?)

    current.each { |prt| prt.mark_for_destruction unless desired.include?(prt.record_type) }
    (desired - current.map(&:record_type)).each { |key| pet_record_types.build(record_type: key) }
  end

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

  # サマリー画面用に、期間内・指定した記録種類(record_types、nilなら全種類)の
  # グラフ系列をまとめて返す(record_type => CareRecord.build_graph_seriesの結果)
  def summary_graph_series(from: 30.days.ago.to_date, to: nil, record_types: nil)
    summary_records(from: from, to: to, record_types: record_types, includes: CareRecord::GRAPH_FIELDS.keys.map(&:to_sym))
      .group_by(&:record_type).filter_map do |record_type, group|
        series = CareRecord.build_graph_series(record_type, group)
        [record_type, series] if series.present?
      end.to_h
  end

  # group_by: "record_type"(既定、記録項目ごとにまとめる) または "date"(日付ごとにまとめる)
  def summary_text(from: 30.days.ago.to_date, to: nil, record_types: nil, group_by: "record_type")
    records = summary_records(
      from: from, to: to, record_types: record_types,
      includes: %i[meal water weight temperature medication toilet walk hospital_visit care]
    ).order(:recorded_at)

    lines = []
    lines << "【#{name}のケア記録サマリー】"
    lines << "期間: #{from ? from.strftime('%Y/%m/%d') : '全期間'} 〜 #{(to || Date.current).strftime('%Y/%m/%d')}"

    if records.empty?
      lines << ""
      lines << "該当期間の記録はありません。"
      return lines.join("\n")
    end

    lines.concat(group_by == "date" ? summary_lines_by_date(records) : summary_lines_by_record_type(records))

    lines.join("\n")
  end

  # サマリー画面で、個々の記録へのリンク一覧を表示するために使う
  def summary_records(from:, to:, record_types:, includes:)
    records = care_records.includes(*includes)
    records = records.where(recorded_at: from.beginning_of_day..) if from
    records = records.where(recorded_at: ..to.end_of_day) if to
    records = records.where(record_type: record_types) if record_types.present?
    records
  end

  private

  # 新規ペットは既存ペットと同様に全種類を初期状態とする。record_type_keys=が
  # (空配列であっても)明示的に呼ばれていれば、その指定を優先して上書きしない
  def seed_default_record_types
    return if @record_type_keys_assigned

    self.record_type_keys = CareRecord::RECORD_TYPE_LABELS.keys
  end

  def record_type_keys_present
    errors.add(:record_type_keys, "を1つ以上選択してください") if record_type_keys.empty?
  end

  def summary_lines_by_record_type(records)
    lines = []
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

    lines
  end

  def summary_lines_by_date(records)
    lines = []

    records.group_by { |care_record| care_record.recorded_at.to_date }.each do |date, group|
      lines << ""
      lines << "■ #{date.strftime('%Y/%m/%d')}"
      group.each do |care_record|
        label = CareRecord::RECORD_TYPE_LABELS[care_record.record_type]
        detail = care_record.detail_summary
        text = detail ? "#{label}: #{detail}" : label
        text += "(#{care_record.note})" if care_record.note.present?
        lines << text
      end
    end

    lines
  end
end
