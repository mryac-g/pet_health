class Water < ApplicationRecord
  belongs_to :care_record

  validates :amount, presence: true

  # 全角数字で入力された場合も保存できるよう、半角に正規化してから型変換する
  def amount=(value)
    value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
    super(value)
  end
end
