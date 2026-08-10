class Weight < ApplicationRecord
  belongs_to :care_record

  validates :weight, presence: true

  # 全角数字で入力された場合も保存できるよう、半角に正規化してから型変換する
  def weight=(value)
    value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
    super(value)
  end
end
