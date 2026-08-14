class Toilet < ApplicationRecord
  belongs_to :care_record

  enum kind: { poop: 0, pee: 1 }
  # 注意: 既存データの整合性のため、新しい状態は必ず末尾に追加すること(番号を変更しない)
  enum condition: { normal: 0, soft: 1, watery: 2, absent: 3, hard: 4 }

  # [値, ラベル, 絵文字] の配列。アイコン選択(icon-picker)で使う
  KIND_OPTIONS = [
    ["poop", "うんち", "💩"],
    ["pee", "おしっこ", "💧"]
  ].freeze

  CONDITION_OPTIONS = [
    ["hard", "かたい", "😖"],
    ["normal", "ふつう", "😊"],
    ["soft", "やわらかい", "😕"],
    ["watery", "下痢", "😣"],
    ["absent", "出なかった", "😐"]
  ].freeze

  CONDITION_LABELS = CONDITION_OPTIONS.to_h { |value, label, _emoji| [value, label] }.freeze

  validates :kind, presence: true
end
