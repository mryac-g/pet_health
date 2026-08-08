class Pet < ApplicationRecord
  belongs_to :user

  has_many :care_records, dependent: :destroy

  enum species: { dog: 0, cat: 1, rabbit: 2, bird: 3, other: 4 }

  SPECIES_LABELS = { "dog" => "犬", "cat" => "猫", "rabbit" => "うさぎ", "bird" => "鳥", "other" => "その他" }.freeze

  validates :name, presence: true

  def last_meal
    Meal.joins(:care_record).where(care_records: { pet_id: id }).order(created_at: :desc).first
  end

  def weight_series
    care_records.weight.includes(:weight).order(:recorded_at).filter_map do |care_record|
      next unless care_record.weight

      { date: care_record.recorded_at.strftime("%m/%d"), value: care_record.weight.weight.to_f }
    end
  end

  def meal_series
    care_records.meal.includes(:meal).order(:recorded_at).filter_map do |care_record|
      next unless care_record.meal

      { date: care_record.recorded_at.strftime("%m/%d"), value: care_record.meal.amount.to_f }
    end
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
