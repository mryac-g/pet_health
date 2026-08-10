# 小数点以下が0の場合は整数として、それ以外はそのまま文字列に整形する
module NumberFormatter
  def self.format(value)
    return nil if value.nil?

    float_value = value.to_f
    float_value % 1 == 0 ? float_value.to_i.to_s : float_value.to_s
  end
end
