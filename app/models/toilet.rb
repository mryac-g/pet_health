class Toilet < ApplicationRecord
  belongs_to :care_record

  enum kind: { poop: 0, pee: 1 }
  enum condition: { normal: 0, soft: 1, watery: 2, absent: 3 }

  # [値, ラベル, 絵文字] の配列。アイコン選択(icon-picker)で使う
  KIND_OPTIONS = [
    ["poop", "うんち", "💩"],
    ["pee", "おしっこ", "💧"]
  ].freeze

  CONDITION_OPTIONS = [
    ["normal", "普通", "😊"],
    ["soft", "軟便", "😕"],
    ["watery", "水様便", "😣"],
    ["absent", "出なかった", "😐"]
  ].freeze

  CONDITION_LABELS = CONDITION_OPTIONS.to_h { |value, label, _emoji| [value, label] }.freeze

  validates :kind, presence: true
end
