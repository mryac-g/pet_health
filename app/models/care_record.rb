class CareRecord < ApplicationRecord
  belongs_to :pet

  has_one :meal, dependent: :destroy
  has_one :water, dependent: :destroy
  has_one :weight, dependent: :destroy
  has_one :temperature, dependent: :destroy
  has_one :medication, dependent: :destroy
  has_one :toilet, dependent: :destroy
  has_one :walk, dependent: :destroy
  has_one :hospital_visit, dependent: :destroy
  has_one :care, dependent: :destroy
  has_many :attachments, dependent: :destroy

  accepts_nested_attributes_for :meal, reject_if: :all_blank
  accepts_nested_attributes_for :water, reject_if: :all_blank
  accepts_nested_attributes_for :weight, reject_if: :all_blank
  accepts_nested_attributes_for :temperature, reject_if: :all_blank
  accepts_nested_attributes_for :medication, reject_if: :all_blank
  accepts_nested_attributes_for :toilet, reject_if: :all_blank
  accepts_nested_attributes_for :walk, reject_if: :all_blank
  accepts_nested_attributes_for :hospital_visit, reject_if: :all_blank
  accepts_nested_attributes_for :care, reject_if: :all_blank

  # 注意: 既存データの整合性のため、新しい記録の種類は必ず末尾に追加すること(番号を変更しない)
  enum record_type: {
    meal: 0,
    weight: 1,
    temperature: 2,
    medication: 3,
    toilet: 4,
    walk: 5,
    hospital_visit: 6,
    abnormality_note: 7,
    water: 8,
    care: 9
  }

  RECORD_TYPE_LABELS = {
    "meal" => "食事",
    "water" => "水",
    "weight" => "体重",
    "temperature" => "体温",
    "medication" => "投薬",
    "toilet" => "排泄",
    "walk" => "散歩",
    "hospital_visit" => "通院",
    "care" => "お手入れ",
    "abnormality_note" => "異常メモ"
  }.freeze

  validates :record_type, presence: true
  validates :recorded_at, presence: true

  DETAIL_ASSOCIATIONS = %i[meal water weight temperature medication toilet walk hospital_visit care].freeze

  # 記録一覧のグラフ化対象。record_type => [[詳細レコードの関連名, フィールド名, グラフの凡例], ...]
  GRAPH_FIELDS = {
    "meal" => [[:meal, :amount, "食事量"]],
    "water" => [[:water, :amount, "水の量(ml)"]],
    "weight" => [[:weight, :weight, "体重(kg)"]],
    "temperature" => [[:temperature, :temperature, "体温(℃)"]],
    "medication" => [[:medication, :dosage_amount, "投薬量"]],
    "walk" => [[:walk, :duration_minutes, "散歩時間(分)"], [:walk, :distance, "散歩距離(km)"]]
  }.freeze

  # 渡されたrecordsの集合から、record_typeに対応するGRAPH_FIELDSの数値フィールドごとに
  # グラフ用の系列(日付/値の点、件数・合計・平均)を組み立てる
  def self.build_graph_series(record_type, records)
    fields = GRAPH_FIELDS[record_type]
    return [] unless fields

    ordered_records = records.sort_by(&:recorded_at)

    fields.filter_map do |association, field, label|
      points = ordered_records.filter_map do |care_record|
        detail = care_record.public_send(association)
        next unless detail

        value = detail.public_send(field)
        next if value.nil?

        {
          x: (care_record.recorded_at.to_f * 1000).round, y: value.to_f,
          recorded_at: care_record.recorded_at.strftime("%Y/%m/%d %H:%M"), note: care_record.note.presence
        }
      end

      next if points.blank?

      values = points.map { |p| p[:y] }
      { label: label, points: points, count: values.size, sum: values.sum.round(2), average: (values.sum / values.size).round(2) }
    end
  end

  # 記録の種類ごとにどの詳細レコードを使うかは実行時にしか決まらないため、
  # フォーム表示用に全種類の空インスタンスを用意しておく
  def build_missing_details
    DETAIL_ASSOCIATIONS.each { |association| send(association) || send("build_#{association}") }
  end

  def detail_summary
    case record_type
    when "meal"
      return nil unless meal

      completion = meal.completion_rate.present? ? "完食率#{NumberFormatter.format(meal.completion_rate)}%" : "完食率未選択"
      [meal.food_name, "#{NumberFormatter.format(meal.amount)}#{meal.unit.presence || 'g'}(#{completion})"].compact.join(" ")
    when "water" then water && "#{NumberFormatter.format(water.amount)}ml"
    when "weight" then weight && "#{NumberFormatter.format(weight.weight)}kg"
    when "temperature" then temperature && "#{NumberFormatter.format(temperature.temperature)}℃"
    when "medication"
      return nil unless medication

      dosage = medication.dosage_amount.present? ? "#{NumberFormatter.format(medication.dosage_amount)}#{medication.dosage_unit}" : "未選択"
      "#{medication.medicine_name}(#{dosage})"
    when "toilet"
      return nil unless toilet

      if toilet.pee?
        "おしっこ"
      else
        condition_label = toilet.condition.present? ? Toilet::CONDITION_LABELS[toilet.condition] : "未選択"
        "うんち(#{condition_label})"
      end
    when "walk"
      return nil unless walk

      duration = walk.duration_minutes.present? ? "#{walk.duration_minutes}分" : "未選択"
      distance = walk.distance.present? ? "#{NumberFormatter.format(walk.distance)}km" : "未選択"
      "#{duration} #{distance}"
    when "hospital_visit"
      return nil unless hospital_visit

      [hospital_visit.hospital_name, hospital_visit.vaccine_type].compact_blank.join(" / ")
    when "care"
      return nil unless care

      Care::CARE_TYPE_LABELS[care.care_type]
    end
  end
end
