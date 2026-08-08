class Meal < ApplicationRecord
  belongs_to :care_record

  COMPLETION_RATE_OPTIONS = {
    "完食" => 100,
    "ほとんど完食" => 75,
    "半分食べた" => 50,
    "あまり食べなかった" => 25
  }.freeze

  validates :amount, presence: true

  # 全角数字で入力された場合も保存できるよう、半角に正規化してから型変換する
  def amount=(value)
    value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
    super(value)
  end
end
