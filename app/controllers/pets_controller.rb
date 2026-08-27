class PetsController < ApplicationController
  include DateRangeFilterable

  # サマリー画面で、記録項目を一度も選んだことが無い場合(初回訪問・全選択解除後)のデフォルト選択
  DEFAULT_SUMMARY_RECORD_TYPES = %w[meal].freeze
  DEFAULT_SUMMARY_GROUP_BY = "record_type"

  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update summary]

  def show
    @latest_care_records = @pet.latest_care_records_by_type
  end

  def summary
    if DateRangeFilterable::PERIOD_PRESETS.key?(params[:period])
      @from, @to = resolve_period_preset(params[:period])
      store_date_range_filter(summary_date_range_scope, @from, @to)
      session[unbounded_from_session_key] = (params[:period] == "all")
      @period = params[:period]
      store_period(@period)
    elsif params.key?(:from) || params.key?(:to)
      @from = parse_date(params[:from])
      @to = parse_date(params[:to])
      store_date_range_filter(summary_date_range_scope, @from, @to)
      session[unbounded_from_session_key] = false
      @period = nil
      store_period(@period)
    else
      @from, @to = restore_date_range_filter(summary_date_range_scope)
      @period = restore_period
    end
    # 「全期間」プリセットが選ばれた(下限なしが意図的)のか、一度もフィルタを
    # 選んだことが無い(下限なしがデフォルト30日にフォールバックすべき)のかを
    # 区別するため、専用のセッションフラグで「全期間」の選択を記憶しておく
    @from ||= 30.days.ago.to_date unless session[unbounded_from_session_key]

    if params.key?(:record_types)
      @record_types = Array(params[:record_types]) & CareRecord.record_types.keys
      store_record_types(@record_types)
    else
      @record_types = restore_record_types
    end
    @record_types = DEFAULT_SUMMARY_RECORD_TYPES if @record_types.blank?

    if params[:group_by].in?(%w[record_type date])
      @group_by = params[:group_by]
      store_group_by(@group_by)
    else
      @group_by = restore_group_by || DEFAULT_SUMMARY_GROUP_BY
    end

    # 食事(g・袋など)・投薬(錠・mlなど)はユーザーごとに単位が複数登録されうるため、
    # 単位を指定しないと合計・平均やグラフが混在した単位のまま計算されてしまう。
    # 未指定(nil)なら従来通り単位混在のまま全件を対象にする
    if params.key?(:meal_unit)
      @meal_unit = params[:meal_unit].presence
      store_meal_unit(@meal_unit)
    else
      @meal_unit = restore_meal_unit
    end

    if params.key?(:medication_unit)
      @medication_unit = params[:medication_unit].presence
      store_medication_unit(@medication_unit)
    else
      @medication_unit = restore_medication_unit
    end

    @meal_units = @pet.meal_units_in_use
    @medication_units = @pet.medication_units_in_use

    if params.key?(:reflect_meal_completion_rate)
      @reflect_meal_completion_rate = params[:reflect_meal_completion_rate] == "1"
      store_reflect_meal_completion_rate(@reflect_meal_completion_rate)
    else
      @reflect_meal_completion_rate = restore_reflect_meal_completion_rate
    end
    @completion_rate_meals_in_range = @record_types.include?("meal") && @pet.completion_rate_meals_in_range?(from: @from, to: @to)
    @reflect_meal_completion_rate &&= @completion_rate_meals_in_range

    @summary_text = @pet.summary_text(
      from: @from, to: @to, record_types: @record_types, group_by: @group_by,
      meal_unit: @meal_unit, medication_unit: @medication_unit, reflect_meal_completion_rate: @reflect_meal_completion_rate
    )
    @summary_entries = @pet.summary_entries(
      from: @from, to: @to, record_types: @record_types, group_by: @group_by,
      meal_unit: @meal_unit, medication_unit: @medication_unit, reflect_meal_completion_rate: @reflect_meal_completion_rate
    )
    @graph_series_by_type = @pet.summary_graph_series(
      from: @from, to: @to, record_types: @record_types, meal_unit: @meal_unit, medication_unit: @medication_unit,
      reflect_meal_completion_rate: @reflect_meal_completion_rate
    )
    # 「編集する」ボタンから戻ってきたとき、直前まで見ていた記録の位置までスクロールするために使う
    @scroll_to = params[:scroll_to].presence

    set_pdf_filename if request.env["Rack-Middleware-Grover"] == "true"
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to pet_path(@pet), notice: "#{@pet.name}を登録しました", alert: upload_icon
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @pet.update(pet_params)
      redirect_to pet_path(@pet), notice: "#{@pet.name}の情報を更新しました", alert: upload_icon
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:id])
  end

  def summary_date_range_scope
    "summary:#{@pet.id}"
  end

  def unbounded_from_session_key
    "summary_unbounded_from:#{@pet.id}"
  end

  # 期間プリセットの<select>に現在有効な値を表示させるために使う。これが無いと
  # 「全期間」等を選んだ直後に「表示する」を押しただけで、選択状態が失われて
  # デフォルトの期間に戻ってしまう
  def period_session_key
    "summary_period:#{@pet.id}"
  end

  def store_period(period)
    session[period_session_key] = period
  end

  def restore_period
    session[period_session_key]
  end

  def record_types_session_key
    "summary_record_types:#{@pet.id}"
  end

  def store_record_types(record_types)
    session[record_types_session_key] = record_types
  end

  def group_by_session_key
    "summary_group_by:#{@pet.id}"
  end

  def store_group_by(group_by)
    session[group_by_session_key] = group_by
  end

  def restore_group_by
    session[group_by_session_key]
  end

  def restore_record_types
    session[record_types_session_key]
  end

  def meal_unit_session_key
    "summary_meal_unit:#{@pet.id}"
  end

  def store_meal_unit(meal_unit)
    session[meal_unit_session_key] = meal_unit
  end

  def restore_meal_unit
    session[meal_unit_session_key]
  end

  def medication_unit_session_key
    "summary_medication_unit:#{@pet.id}"
  end

  def store_medication_unit(medication_unit)
    session[medication_unit_session_key] = medication_unit
  end

  def reflect_meal_completion_rate_session_key
    "summary_reflect_meal_completion_rate:#{@pet.id}"
  end

  def store_reflect_meal_completion_rate(value)
    session[reflect_meal_completion_rate_session_key] = value
  end

  def restore_reflect_meal_completion_rate
    session[reflect_meal_completion_rate_session_key] || false
  end

  def restore_medication_unit
    session[medication_unit_session_key]
  end

  # PDF化(Grover::Middleware経由)時のみ、ペット名と対象記録項目からファイル名を組み立てる。
  # 通常のHTML表示では設定しない(強制ダウンロードになってしまうため)
  def set_pdf_filename
    labels = @record_types.map { |record_type| CareRecord::RECORD_TYPE_LABELS[record_type] }
    filename = "#{@pet.name}_#{labels.join('_')}.pdf"
    response.headers["Content-Disposition"] =
      ActionDispatch::Http::ContentDisposition.format(disposition: "attachment", filename: filename)
  end

  def pet_params
    params.require(:pet).permit(:name, :species, :species_note, :birthday, :welcomed_on, :icon_url, record_type_keys: [])
  end

  def upload_icon
    @pet.upload_icon!(params.dig(:pet, :icon))
    nil
  rescue Pet::UnsupportedIconContentTypeError
    "対応していない画像形式です"
  rescue Pet::IconTooLargeError
    "画像サイズは5MB以内にしてください"
  rescue => e
    Rails.logger.error("Pet icon upload failed: #{e.class}: #{e.message}")
    "アイコンのアップロードに失敗しました"
  end
end
