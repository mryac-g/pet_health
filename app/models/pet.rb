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

  # サマリー画面の「食事の単位」絞り込みの選択肢。単位が複数登録されうるため、
  # 実際に記録で使われている単位だけを候補にする(未登録の単位を選べても意味が無いため)
  def meal_units_in_use
    Meal.joins(:care_record).where(care_records: { pet_id: id }).distinct.pluck(:unit).compact_blank.sort
  end

  # 投薬の単位も同様(Medication::DOSAGE_UNITSは選択肢の全体集合だが、
  # このペットで実際に使われている単位だけに絞る)
  def medication_units_in_use
    Medication.joins(:care_record).where(care_records: { pet_id: id }).distinct.pluck(:dosage_unit).compact_blank.sort
  end

  def latest_care_records_by_type
    care_records
      .includes(*CareRecord::DETAIL_ASSOCIATIONS, :attachments)
      .order(recorded_at: :desc)
      .group_by(&:record_type)
      .transform_values(&:first)
  end

  # サマリー画面用に、期間内・指定した記録種類(record_types、nilなら全種類)の
  # グラフ系列をまとめて返す(record_type => CareRecord.build_graph_seriesの結果)。
  # meal_unit/medication_unitは、単位が混在しがちな食事・投薬だけを対象にした絞り込み
  def summary_graph_series(from: 30.days.ago.to_date, to: nil, record_types: nil, meal_unit: nil, medication_unit: nil)
    summary_records(
      from: from, to: to, record_types: record_types, includes: CareRecord::GRAPH_FIELDS.keys.map(&:to_sym),
      meal_unit: meal_unit, medication_unit: medication_unit
    ).group_by(&:record_type).filter_map do |record_type, group|
      series = CareRecord.build_graph_series(record_type, group)
      [record_type, series] if series.present?
    end.to_h
  end

  # group_by: "record_type"(既定、記録項目ごとにまとめる) または "date"(日付ごとにまとめる)
  def summary_text(from: 30.days.ago.to_date, to: nil, record_types: nil, group_by: "record_type", meal_unit: nil, medication_unit: nil)
    lines = []
    lines << "【#{name}の記録サマリー】"
    lines << "期間: #{from ? from.strftime('%Y/%m/%d') : '全期間'} 〜 #{(to || Date.current).strftime('%Y/%m/%d')}"

    entries = summary_entries(
      from: from, to: to, record_types: record_types, group_by: group_by, meal_unit: meal_unit, medication_unit: medication_unit
    )

    if entries.empty?
      lines << ""
      lines << "該当期間の記録はありません。"
      return lines.join("\n")
    end

    entries.each do |entry|
      if entry[:header]
        lines << ""
        lines << "■ #{entry[:header]}"
      else
        lines << entry[:text]
      end
    end

    lines.join("\n")
  end

  # サマリー画面のまとめ文章から個々の記録の編集画面へ直接遷移できるようにするために使う。
  # summary_textと同じ形式の行データを、対応するcare_record付きで返す
  # (ヘッダー行は{ header: "食事" }、記録行は{ care_record:, text: }の形)
  def summary_entries(from: 30.days.ago.to_date, to: nil, record_types: nil, group_by: "record_type", meal_unit: nil, medication_unit: nil)
    records = summary_records(
      from: from, to: to, record_types: record_types, includes: CareRecord::DETAIL_ASSOCIATIONS + [:attachments],
      meal_unit: meal_unit, medication_unit: medication_unit
    )
    return [] if records.empty?

    group_by == "date" ? summary_entries_by_date(records) : summary_entries_by_record_type(records)
  end

  # サマリー画面で、個々の記録へのリンク一覧を表示するために使う。食事・投薬は
  # ユーザーごとに単位が複数登録できるため、meal_unit/medication_unitを指定すると
  # その単位の記録だけに絞り込む(未指定なら単位混在のまま全件が対象)
  def summary_records(from:, to:, record_types:, includes:, meal_unit: nil, medication_unit: nil)
    records = care_records.includes(*includes)
    records = records.where(recorded_at: from.beginning_of_day..) if from
    records = records.where(recorded_at: ..to.end_of_day) if to
    records = records.where(record_type: record_types) if record_types.present?
    records = records.order(:recorded_at).to_a
    records = records.reject { |r| r.record_type == "meal" && meal_unit.present? && r.meal&.unit != meal_unit }
    records.reject { |r| r.record_type == "medication" && medication_unit.present? && r.medication&.dosage_unit != medication_unit }
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

  def summary_entries_by_record_type(records)
    entries = []
    grouped = records.group_by(&:record_type)

    CareRecord::RECORD_TYPE_LABELS.each do |record_type, label|
      group = grouped[record_type]
      next if group.blank?

      entries << { header: label }
      group.each do |care_record|
        date = care_record.recorded_at.strftime("%m/%d")
        detail = care_record.detail_summary
        text = detail ? "#{date}: #{detail}" : date
        text += "(#{care_record.note})" if care_record.note.present?
        entries << { care_record: care_record, text: text }
      end
    end

    entries
  end

  def summary_entries_by_date(records)
    entries = []

    records.group_by { |care_record| care_record.recorded_at.to_date }.each do |date, group|
      entries << { header: date.strftime("%Y/%m/%d") }
      group.each do |care_record|
        label = CareRecord::RECORD_TYPE_LABELS[care_record.record_type]
        detail = care_record.detail_summary
        text = detail ? "#{label}: #{detail}" : label
        text += "(#{care_record.note})" if care_record.note.present?
        entries << { care_record: care_record, text: text }
      end
    end

    entries
  end
end
