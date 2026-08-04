class PetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update summary]

  def show
    @pets = current_user.pets
    @weight_series = @pet.weight_series
    @meal_series = @pet.meal_series
  end

  def summary
    @summary_text = @pet.summary_text
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to pet_path(@pet), notice: "#{@pet.name}を登録しました"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @pet.update(pet_params)
      redirect_to pet_path(@pet), notice: "#{@pet.name}の情報を更新しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_pet
    @pet = current_user.pets.find(params[:id])
  end

  def pet_params
    params.require(:pet).permit(:name, :species, :species_note, :birthday, :icon_url)
  end
end
