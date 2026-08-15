# 整数値でも小数第1位まで表示し(例: 5 → "5.0")、小数点を含む記録と表記を揃える。
# 小数第1位を超える精度で入力された値はそのまま保持する(丸めない)
module NumberFormatter
  def self.format(value)
    return nil if value.nil?

    float_value = value.to_f
    float_value % 1 == 0 ? sprintf("%.1f", float_value) : float_value.to_s
  end
end
