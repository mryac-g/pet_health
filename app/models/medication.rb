class Medication < ApplicationRecord
  belongs_to :care_record

  DOSAGE_UNITS = %w[錠 個 ml cc mg g 包 滴].freeze

  validates :medicine_name, presence: true

  # 全角数字で入力された場合も保存できるよう、半角に正規化してから型変換する
  def dosage_amount=(value)
    value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
    super(value)
  end
end
