# from/toの日付範囲フィルタをセッションへ記憶・復元する共通処理。
# 呼び出し側でscope(ペット・記録種類などを含む一意なキー)を渡す。
module DateRangeFilterable
  extend ActiveSupport::Concern

  # from/toを素早く入力するためのショートカット。選んでも手動でfrom/toを編集し直せる
  PERIOD_PRESETS = {
    "last_7_days" => ["過去7日間", -> { [7.days.ago.to_date, Date.current] }],
    "last_month" => ["過去1ヶ月", -> { [1.month.ago.to_date, Date.current] }],
    "last_3_months" => ["過去3ヶ月", -> { [3.months.ago.to_date, Date.current] }],
    "last_year" => ["過去1年間", -> { [1.year.ago.to_date, Date.current] }],
    "all" => ["全期間", -> { [nil, nil] }]
  }.freeze

  private

  def parse_date(value)
    Date.parse(value)
  rescue ArgumentError, TypeError
    nil
  end

  def resolve_period_preset(key)
    DateRangeFilterable::PERIOD_PRESETS[key]&.second&.call
  end

  def date_range_session_key(scope)
    "date_range_filter:#{scope}"
  end

  def store_date_range_filter(scope, from, to)
    session[date_range_session_key(scope)] = { "from" => from&.iso8601, "to" => to&.iso8601 }
  end

  def restore_date_range_filter(scope)
    stored = session[date_range_session_key(scope)]
    return [nil, nil] unless stored

    [parse_date(stored["from"]), parse_date(stored["to"])]
  end
end
