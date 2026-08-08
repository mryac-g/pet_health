class Care < ApplicationRecord
  belongs_to :care_record

  enum care_type: { nail_trim: 0, trimming: 1, shampoo: 2, brushing: 3 }

  CARE_TYPE_OPTIONS = [
    ["nail_trim", "爪切り", "💅"],
    ["trimming", "トリミング", "✂️"],
    ["shampoo", "シャンプー", "🛁"],
    ["brushing", "ブラッシング", "🪮"]
  ].freeze

  CARE_TYPE_LABELS = CARE_TYPE_OPTIONS.to_h { |value, label, _emoji| [value, label] }.freeze

  validates :care_type, presence: true
end
