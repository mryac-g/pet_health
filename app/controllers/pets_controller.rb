class PetsController < ApplicationController
  before_action :authenticate_user!

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to root_path, notice: "#{@pet.name}を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def pet_params
    params.require(:pet).permit(:name, :species, :species_note, :birthday, :icon_url)
  end
end
