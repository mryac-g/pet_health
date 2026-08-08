class Meal < ApplicationRecord
  belongs_to :care_record

  # [値, ラベル, 絵文字] の配列。アイコン選択(icon-picker)で使う
  COMPLETION_RATE_OPTIONS = [
    [100, "完食", "😋"],
    [75, "ほとんど完食", "🙂"],
    [50, "半分食べた", "😐"],
    [25, "あまり食べなかった", "😟"]
  ].freeze

  validates :amount, presence: true

  # 全角数字で入力された場合も保存できるよう、半角に正規化してから型変換する
  def amount=(value)
    value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
    super(value)
  end
end
