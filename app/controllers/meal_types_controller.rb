class MealTypesController < ApplicationController
  before_action :authenticate_user!

  def index
    @meal_types = current_user.meal_types.order(:name)
    @meal_type = current_user.meal_types.new
  end

  def create
    @meal_type = current_user.meal_types.new(meal_type_params)

    if @meal_type.save
      redirect_to meal_types_path, notice: "食事の種類を登録しました"
    else
      @meal_types = current_user.meal_types.order(:name)
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    current_user.meal_types.find(params[:id]).destroy
    redirect_to meal_types_path, notice: "食事の種類を削除しました"
  end

  private

  def meal_type_params
    params.require(:meal_type).permit(:name)
  end
end
