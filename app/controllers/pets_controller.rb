class PetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, only: %i[show]

  def show
    @pets = current_user.pets
  end

  def new
    @pet = current_user.pets.new
  end

  def create
    @pet = current_user.pets.new(pet_params)

    if @pet.save
      redirect_to pet_path(@pet), notice: "#{@pet.name}を登録しました"
    else
      render :new, status: :unprocessable_entity
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
