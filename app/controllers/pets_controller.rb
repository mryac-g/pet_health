class PetsController < ApplicationController
  include DateRangeFilterable

  # サマリー画面で、記録項目を一度も選んだことが無い場合(初回訪問・全選択解除後)のデフォルト選択
  DEFAULT_SUMMARY_RECORD_TYPES = %w[meal].freeze
  DEFAULT_SUMMARY_GROUP_BY = "record_type"

  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update summary]

  def show
    @pets = current_user.pets
    @latest_care_records = @pet.latest_care_records_by_type
  end

  def summary
    if DateRangeFilterable::PERIOD_PRESETS.key?(params[:period])
      @from, @to = resolve_period_preset(params[:period])
      store_date_range_filter(summary_date_range_scope, @from, @to)
    elsif params.key?(:from) || params.key?(:to)
      @from = parse_date(params[:from])
      @to = parse_date(params[:to])
      store_date_range_filter(summary_date_range_scope, @from, @to)
    else
      @from, @to = restore_date_range_filter(summary_date_range_scope)
    end
    @from ||= 30.days.ago.to_date

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

    @summary_text = @pet.summary_text(from: @from, to: @to, record_types: @record_types, group_by: @group_by)
    @graph_series_by_type = @pet.summary_graph_series(from: @from, to: @to, record_types: @record_types)

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

  # PDF化(Grover::Middleware経由)時のみ、ペット名と対象記録項目からファイル名を組み立てる。
  # 通常のHTML表示では設定しない(強制ダウンロードになってしまうため)
  def set_pdf_filename
    labels = @record_types.map { |record_type| CareRecord::RECORD_TYPE_LABELS[record_type] }
    filename = "#{@pet.name}_#{labels.join('_')}.pdf"
    response.headers["Content-Disposition"] =
      ActionDispatch::Http::ContentDisposition.format(disposition: "attachment", filename: filename)
  end

  def pet_params
    params.require(:pet).permit(:name, :species, :species_note, :birthday, :icon_url)
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
