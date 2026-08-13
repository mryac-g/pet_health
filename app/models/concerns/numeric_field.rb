# 全角数字で入力された場合も保存できるよう半角に正規化した上で、
# 数字(符号・小数点含む)以外が混ざっている入力は保存前に弾く
module NumericField
  extend ActiveSupport::Concern

  class_methods do
    def normalizes_numeric_field(field)
      define_method("#{field}=") do |value|
        value = value.tr("０-９．－", "0-9.-") if value.is_a?(String)
        super(value)
      end

      validate do
        raw = public_send("#{field}_before_type_cast")
        next if raw.blank? || raw.is_a?(Numeric)
        next if raw.to_s.match?(/\A-?\d+(\.\d+)?\z/)

        errors.add(field, "は数字のみで入力してください")
      end
    end
  end
end
