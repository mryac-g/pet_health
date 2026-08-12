class PetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pet, only: %i[show edit update summary]

  def show
    @pets = current_user.pets
    @latest_care_records = @pet.latest_care_records_by_type
  end

  def summary
    @summary_text = @pet.summary_text
    @graph_series_by_type = @pet.summary_graph_series
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
