module ApplicationHelper
  # 値が未入力・未選択の場合に「未選択」と表示する
  def display_or_unselected(value, suffix: nil)
    return "未選択" if value.blank?

    suffix ? "#{value}#{suffix}" : value.to_s
  end
end
