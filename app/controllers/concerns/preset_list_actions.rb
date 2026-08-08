module PresetListActions
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def index
    @items = preset_scope.order(:name)
    @item = preset_scope.new
  end

  def create
    @item = preset_scope.new(preset_params)

    if @item.save
      redirect_to preset_index_path, notice: "#{preset_label}を登録しました"
    else
      @items = preset_scope.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    preset_scope.find(params[:id]).destroy
    redirect_to preset_index_path, notice: "#{preset_label}を削除しました"
  end

  private

  def preset_params
    params.require(preset_param_key).permit(:name)
  end
end
