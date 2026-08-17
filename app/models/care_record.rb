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
  validate :recorded_at_not_in_future
  validate :detail_record_present

  DETAIL_ASSOCIATIONS = %i[meal water weight temperature medication toilet walk hospital_visit care].freeze

  # 記録一覧のグラフ化対象。record_type => [[詳細レコードの関連名, フィールド名, グラフの凡例], ...]
  GRAPH_FIELDS = {
    "meal" => [[:meal, :amount, "食事量"]],
    "water" => [[:water, :amount, "水の量(ml)"]],
    "weight" => [[:weight, :weight, "体重"]],
    "temperature" => [[:temperature, :temperature, "体温(℃)"]],
    "medication" => [[:medication, :dosage_amount, "投薬量"]],
    "walk" => [[:walk, :duration_minutes, "散歩時間(分)"], [:walk, :distance, "散歩距離(km)"]]
  }.freeze

  # 1グラフに表示する点が多すぎるとX軸の目盛り(記録ごとの日付)が重なって
  # 読めなくなるため、この件数を超えたら日付順に複数のグラフへ分割する
  MAX_POINTS_PER_GRAPH = 15

  # 渡されたrecordsの集合から、record_typeに対応するGRAPH_FIELDSの数値フィールドごとに
  # グラフ用の系列(日付/値の点、件数・合計・平均、表示用に分割した点のかたまり)を組み立てる。
  # reflect_meal_completion_rate: 食事の量を完食率で換算した実質量をグラフに使うかどうか
  # (完食率が入力されている記録のみ換算し、未入力の記録は元の量のまま扱う)
  def self.build_graph_series(record_type, records, reflect_meal_completion_rate: false)
    fields = GRAPH_FIELDS[record_type]
    return [] unless fields

    ordered_records = records.sort_by(&:recorded_at)
    adjust_meal = record_type == "meal" && reflect_meal_completion_rate

    fields.filter_map do |association, field, label|
      points = ordered_records.filter_map do |care_record|
        detail = care_record.public_send(association)
        next unless detail

        value = detail.public_send(field)
        next if value.nil?

        value = meal_completion_rate_adjusted_amount(detail) if adjust_meal

        {
          x: (care_record.recorded_at.to_f * 1000).round, y: value.to_f,
          recorded_at: care_record.recorded_at.strftime("%Y/%m/%d %H:%M"), note: care_record.note.presence
        }
      end

      next if points.blank?

      values = points.map { |p| p[:y] }
      {
        label: adjust_meal ? "#{label}(完食率換算)" : label, points: points,
        point_chunks: split_into_even_chunks(points, MAX_POINTS_PER_GRAPH),
        count: values.size, sum: values.sum.round(2), average: (values.sum / values.size).round(2)
      }
    end
  end

  # 完食率が入力されている場合のみ、量を完食率で割った実質量に換算する。
  # 完食率0はゼロ除算になるため、通常のamountのまま扱う
  def self.meal_completion_rate_adjusted_amount(meal)
    return meal.amount if meal.completion_rate.blank? || meal.completion_rate.zero?

    meal.amount.to_f / (meal.completion_rate.to_f / 100.0)
  end

  # each_sliceのようにmax_size件ずつ機械的に区切ると、末尾のグラフだけ極端に
  # 点数が少なくなることがある(例: 17件をmax_size=15で区切ると15件+2件)ため、
  # 必要なグラフ数を先に決めてから、その数でできるだけ均等に分配する
  # (17件・上限15なら2グラフ必要と分かるので、9件+8件に分ける)
  def self.split_into_even_chunks(points, max_size)
    chunk_count = (points.size / max_size.to_f).ceil
    chunk_size = (points.size / chunk_count.to_f).ceil
    points.each_slice(chunk_size).to_a
  end
  private_class_method :split_into_even_chunks

  # 記録の種類ごとにどの詳細レコードを使うかは実行時にしか決まらないため、
  # フォーム表示用に全種類の空インスタンスを用意しておく
  def build_missing_details
    DETAIL_ASSOCIATIONS.each { |association| send(association) || send("build_#{association}") }
  end

  def detail_summary(reflect_meal_completion_rate: false)
    build_detail_summary(reflect_meal_completion_rate: reflect_meal_completion_rate)
  end

  private

  def recorded_at_not_in_future
    return if recorded_at.blank? || recorded_at <= Time.current

    errors.add(:recorded_at, "は#{Time.current.strftime('%Y年%m月%d日 %H:%M')}より前の日時にしてください")
  end

  # 詳細レコード(Water/Weight等)はaccepts_nested_attributes_forのreject_if: :all_blankにより、
  # フォームが未入力のまま送信されるとビルドすらされない。そのため詳細モデル側のpresenceバリデーションが
  # 一度も走らず、中身の無いCareRecordだけが保存できてしまう。record_typeに対応する詳細レコードが
  # 実際に存在するかをここで確認する(abnormality_noteのみ詳細レコードを持たないため対象外)
  def detail_record_present
    return if record_type.blank? || record_type == "abnormality_note"

    detail = public_send(record_type)
    errors.add(:base, "を入力してください") if detail.blank?
  end

  def build_detail_summary(reflect_meal_completion_rate: false)
    case record_type
    when "meal"
      return nil unless meal

      amount_text = "#{NumberFormatter.format(meal.amount)}#{meal.unit.presence || 'g'}"
      if reflect_meal_completion_rate && meal.completion_rate.present? && meal.completion_rate.positive?
        adjusted = CareRecord.meal_completion_rate_adjusted_amount(meal)
        amount_text += "(#{NumberFormatter.format(adjusted)}#{meal.unit.presence || 'g'})"
      else
        completion = Meal.completion_rate_label(meal.completion_rate) || (meal.completion_rate.present? && "#{NumberFormatter.format(meal.completion_rate)}%")
        amount_text += "(#{completion})" if completion
      end
      [meal.food_name, amount_text].compact.join(" ")
    when "water" then water && "#{NumberFormatter.format(water.amount)}ml"
    when "weight" then weight && "#{NumberFormatter.format(weight.weight)}#{weight.unit}"
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
