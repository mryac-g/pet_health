class CareRecord < ApplicationRecord
  belongs_to :pet

  has_one :meal, dependent: :destroy
  has_one :weight, dependent: :destroy
  has_one :temperature, dependent: :destroy
  has_one :medication, dependent: :destroy
  has_one :walk, dependent: :destroy
  has_one :hospital_visit, dependent: :destroy
  has_many :attachments, dependent: :destroy

  accepts_nested_attributes_for :meal, reject_if: :all_blank
  accepts_nested_attributes_for :weight, reject_if: :all_blank
  accepts_nested_attributes_for :temperature, reject_if: :all_blank
  accepts_nested_attributes_for :medication, reject_if: :all_blank
  accepts_nested_attributes_for :walk, reject_if: :all_blank
  accepts_nested_attributes_for :hospital_visit, reject_if: :all_blank

  enum record_type: {
    meal: 0,
    weight: 1,
    temperature: 2,
    medication: 3,
    toilet: 4,
    walk: 5,
    hospital_visit: 6,
    abnormality_note: 7
  }

  RECORD_TYPE_LABELS = {
    "meal" => "食事",
    "weight" => "体重",
    "temperature" => "体温",
    "medication" => "投薬",
    "toilet" => "排泄",
    "walk" => "散歩",
    "hospital_visit" => "通院",
    "abnormality_note" => "異常メモ"
  }.freeze

  validates :record_type, presence: true
  validates :recorded_at, presence: true

  DETAIL_ASSOCIATIONS = %i[meal weight temperature medication walk hospital_visit].freeze

  # 記録の種類ごとにどの詳細レコードを使うかは実行時にしか決まらないため、
  # フォーム表示用に全種類の空インスタンスを用意しておく
  def build_missing_details
    DETAIL_ASSOCIATIONS.each { |association| send(association) || send("build_#{association}") }
  end

  def detail_summary
    case record_type
    when "meal"
      return nil unless meal

      completion = meal.completion_rate.present? ? "完食率#{meal.completion_rate}%" : "完食率未選択"
      [meal.food_name, "#{meal.amount}#{meal.unit.presence || 'g'}(#{completion})"].compact.join(" ")
    when "weight" then weight && "#{weight.weight}kg"
    when "temperature" then temperature && "#{temperature.temperature}℃"
    when "medication"
      return nil unless medication

      "#{medication.medicine_name}(#{medication.dosage.presence || '未選択'})"
    when "walk"
      return nil unless walk

      duration = walk.duration_minutes.present? ? "#{walk.duration_minutes}分" : "未選択"
      distance = walk.distance.present? ? "#{walk.distance}km" : "未選択"
      "#{duration} #{distance}"
    when "hospital_visit" then hospital_visit && hospital_visit.hospital_name
    end
  end
end
