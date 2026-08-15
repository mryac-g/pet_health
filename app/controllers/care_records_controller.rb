class CareRecordsController < ApplicationController
  include DateRangeFilterable

  DETAIL_ATTRIBUTES = {
    meal_attributes: %i[food_name unit amount completion_rate],
    water_attributes: %i[amount],
    weight_attributes: %i[weight],
    temperature_attributes: %i[temperature],
    medication_attributes: %i[medicine_name dosage_amount dosage_unit],
    toilet_attributes: %i[kind condition],
    walk_attributes: %i[duration_minutes distance],
    hospital_visit_attributes: %i[hospital_name vaccine_type diagnosis],
    care_attributes: %i[care_type]
  }.freeze

  # 食事(g・袋など)・投薬(錠・mlなど)はユーザーごとに単位が複数登録されうるため、
  # 単位を絞り込めないと合計・平均やグラフが混在した単位のまま計算されてしまう(issue #170)
  UNIT_FILTERABLE_RECORD_TYPES = %w[meal medication].freeze

  before_action :authenticate_user!
  before_action :set_pet
  before_action :set_care_record, only: %i[show edit update destroy]
  before_action :set_meal_presets, only: %i[new create edit update]
  before_action :set_medicine_types, only: %i[new create edit update]
  before_action :set_hospital_visit_presets, only: %i[new create edit update]

  def index
    @record_type = params[:record_type] if CareRecord.record_types.key?(params[:record_type])

    if DateRangeFilterable::PERIOD_PRESETS.key?(params[:period])
      @from, @to = resolve_period_preset(params[:period])
      store_date_range_filter(date_range_scope, @from, @to) if @record_type
    elsif params.key?(:from) || params.key?(:to)
      @from = parse_date(params[:from])
      @to = parse_date(params[:to])
      store_date_range_filter(date_range_scope, @from, @to) if @record_type
    elsif @record_type
      @from, @to = restore_date_range_filter(date_range_scope)
    end

    if @record_type.in?(UNIT_FILTERABLE_RECORD_TYPES)
      if params.key?(:unit)
        @unit = params[:unit].presence
        store_unit_filter(@unit)
      else
        @unit = restore_unit_filter
      end
      @units_in_use = units_in_use_for(@record_type)
    end

    @care_records = @pet.care_records
                         .includes(*CareRecord::DETAIL_ASSOCIATIONS)
                         .order(recorded_at: :desc)
    @care_records = @care_records.where(record_type: @record_type) if @record_type
    @care_records = @care_records.where(recorded_at: @from.beginning_of_day..) if @from
    @care_records = @care_records.where(recorded_at: ..@to.end_of_day) if @to
    @care_records = filter_by_unit(@care_records, @record_type, @unit) if @unit.present?
    @graph_series = @record_type ? build_graph_series : []
  end

  # 記録詳細画面から、一覧に遷移せずグラフだけをモーダルで見られるようにする
  def graph
    @record_type = params[:record_type] if CareRecord.record_types.key?(params[:record_type])
    @from, @to = @record_type ? restore_date_range_filter(date_range_scope) : [nil, nil]
    @unit = restore_unit_filter if @record_type.in?(UNIT_FILTERABLE_RECORD_TYPES)

    @care_records = @pet.care_records.includes(*CareRecord::DETAIL_ASSOCIATIONS)
    @care_records = @care_records.where(record_type: @record_type) if @record_type
    @care_records = @care_records.where(recorded_at: @from.beginning_of_day..) if @from
    @care_records = @care_records.where(recorded_at: ..@to.end_of_day) if @to
    @care_records = filter_by_unit(@care_records, @record_type, @unit) if @unit.present?
    @graph_series = @record_type ? build_graph_series : []
  end

  def show
  end

  def new
    requested_type = params[:record_type]
    return redirect_to pet_path(@pet), alert: disabled_record_type_alert(requested_type) if disabled_for_pet?(requested_type)

    record_type = @pet.record_type_keys.include?(requested_type) ? requested_type : @pet.record_type_keys.first
    @care_record = @pet.care_records.new(record_type: record_type, recorded_at: Time.current.change(sec: 0))
    @care_record.build_missing_details
    @return_to = safe_local_path(params[:return_to])
    prefill_last_meal_choices
    prefill_last_medication_choices
    @recent_care_records = recent_records_for(record_type) if record_type == "meal"
  end

  def create
    requested_type = params.dig(:care_record, :record_type)
    return redirect_to pet_path(@pet), alert: disabled_record_type_alert(requested_type) if disabled_for_pet?(requested_type)

    @care_record = @pet.care_records.new(care_record_params)

    if @care_record.save
      redirect_to safe_local_path(params[:return_to]) || pet_care_records_path(@pet, record_type: @care_record.record_type),
        notice: "#{CareRecord::RECORD_TYPE_LABELS[@care_record.record_type]}を登録しました", alert: upload_attachments
    else
      @care_record.build_missing_details
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @care_record.build_missing_details
    @return_to = safe_local_path(params[:return_to])
  end

  def update
    if @care_record.update(care_record_update_params)
      redirect_to safe_local_path(params[:return_to]) || pet_care_records_path(@pet, record_type: @care_record.record_type),
        notice: "#{CareRecord::RECORD_TYPE_LABELS[@care_record.record_type]}を更新しました", alert: upload_attachments
    else
      @care_record.build_missing_details
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @care_record.destroy
    redirect_to pet_care_records_path(@pet), notice: "記録を削除しました"
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:pet_id])
  end

  # "＋"ボタンを押した元のページ(ペットのトップページ or 記録種類の一覧ページ)に
  # 登録後戻れるよう、new/createの間でパスを引き回す。外部URLへのオープンリダイレクトを
  # 防ぐため、"/"始まりかつ"//"始まりでないアプリ内の相対パスのみ許可する
  def safe_local_path(path)
    path if path.present? && path.start_with?("/") && !path.start_with?("//")
  end

  # ペット×記録種類ごとに直近の日付範囲フィルタをセッションへ記憶し、次回同じ一覧を
  # 開いたとき(from/toパラメータ無しでのアクセス)に復元する
  def date_range_scope
    "care_records:#{@pet.id}:#{@record_type}"
  end

  # 表示中の@care_records(絞り込み・日付範囲を反映済み)から、記録の種類ごとに定義された
  # 数値フィールド(CareRecord::GRAPH_FIELDS)のグラフ用データを組み立てる
  def build_graph_series
    CareRecord.build_graph_series(@record_type, @care_records)
  end

  def units_in_use_for(record_type)
    record_type == "meal" ? @pet.meal_units_in_use : @pet.medication_units_in_use
  end

  # 食事はMeal#unit、投薬はMedication#dosage_unitで単位を保持するフィールド名が異なるため、
  # record_typeに応じて絞り込み対象のフィールドを切り替える
  def filter_by_unit(records, record_type, unit)
    case record_type
    when "meal" then records.joins(:meal).where(meals: { unit: unit })
    when "medication" then records.joins(:medication).where(medications: { dosage_unit: unit })
    else records
    end
  end

  def unit_session_key
    "unit_filter:#{date_range_scope}"
  end

  def store_unit_filter(unit)
    session[unit_session_key] = unit
  end

  def restore_unit_filter
    session[unit_session_key]
  end

  def set_care_record
    @care_record = @pet.care_records.find(params[:id])
  end

  # 登録フォームの横に表示する「最近の記録」パネル用に直近5件を取得する
  def recent_records_for(record_type)
    @pet.care_records
        .includes(*CareRecord::DETAIL_ASSOCIATIONS)
        .where(record_type: record_type)
        .order(recorded_at: :desc)
        .limit(5)
  end

  def set_meal_presets
    @meal_types = current_user.meal_types.order(:name)
    @meal_units = current_user.meal_units.order(:name)
  end

  def set_medicine_types
    @medicine_types = current_user.medicine_types.order(:name)
  end

  def set_hospital_visit_presets
    @hospital_names = current_user.hospital_names.order(:name)
    @vaccine_types = current_user.vaccine_types.order(:name)
  end

  # そのペットで有効化されていない記録項目かどうか(グローバルに存在しない値はここでは対象外)
  def disabled_for_pet?(record_type)
    CareRecord.record_types.key?(record_type) && !@pet.record_type_keys.include?(record_type)
  end

  def disabled_record_type_alert(record_type)
    "#{CareRecord::RECORD_TYPE_LABELS[record_type]}はこのペットでは記録できません"
  end

  # ペットごとに、前回記録した食事の種類・単位をあらかじめ選択された状態にする
  def prefill_last_meal_choices
    last_meal = @pet.last_meal
    return unless last_meal

    @care_record.meal.food_name ||= last_meal.food_name
    # unitはDBの既定値"g"が既に入っているため||=だと発火しない。前回の単位(未指定なら
    # それ自体が"g")を明示的に反映する
    @care_record.meal.unit = last_meal.unit
  end

  # ペットごとに、前回記録した薬の種類・容量の単位をあらかじめ選択された状態にする
  def prefill_last_medication_choices
    last_medication = @pet.last_medication
    return unless last_medication

    @care_record.medication.medicine_name ||= last_medication.medicine_name
    @care_record.medication.dosage_unit ||= last_medication.dosage_unit
  end

  # フォームで選択された添付ファイルをアップロードする。失敗しても記録自体は保存済みのため、
  # エラーメッセージを返すのみで記録の保存処理には影響させない
  def upload_attachments
    attachment_files.each { |file| Attachment.upload!(care_record: @care_record, file: file) }
    nil
  rescue Attachment::UnsupportedContentTypeError
    "対応していないファイル形式があったため、一部のファイルはアップロードされませんでした"
  rescue Attachment::FileTooLargeError
    "ファイルサイズが10MBを超えるものがあったため、一部のファイルはアップロードされませんでした"
  rescue => e
    Rails.logger.error("Supabase Storage upload failed: #{e.class}: #{e.message}")
    "ファイルのアップロードに失敗しました"
  end

  def attachment_files
    Array(params.dig(:care_record, :files)).reject(&:blank?)
  end

  def care_record_params
    params.require(:care_record).permit(:record_type, :recorded_at, :note, **DETAIL_ATTRIBUTES)
  end

  # record_typeは作成後に変更不可(詳細レコードの整合性が崩れるため)
  def care_record_update_params
    detail_attributes_with_id = DETAIL_ATTRIBUTES.transform_values { |fields| [:id, *fields] }
    params.require(:care_record).permit(:recorded_at, :note, **detail_attributes_with_id)
  end
end
