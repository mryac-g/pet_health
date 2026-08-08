module PresetListActions
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def index
    @items = preset_scope.order(:name)
    @item = preset_scope.new
    @back_path = safe_return_to || root_path
  end

  def create
    @item = preset_scope.new(preset_params)

    if @item.save
      redirect_to preset_index_path_with_return, notice: "#{preset_label}を登録しました"
    else
      @items = preset_scope.order(:name)
      @back_path = safe_return_to || root_path
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    preset_scope.find(params[:id]).destroy
    redirect_to preset_index_path_with_return, notice: "#{preset_label}を削除しました"
  end

  private

  def preset_params
    params.require(preset_param_key).permit(:name)
  end

  # 外部URLへ遷移させられないよう、内部の相対パスのみ許可する
  def safe_return_to
    return_to = params[:return_to]
    return nil unless return_to.present? && return_to.start_with?("/") && !return_to.start_with?("//")

    return_to
  end

  def preset_index_path_with_return
    safe_return_to ? "#{preset_index_path}?#{{ return_to: safe_return_to }.to_query}" : preset_index_path
  end
end
