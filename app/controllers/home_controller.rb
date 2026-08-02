class HomeController < ApplicationController
  def index
    @pets = current_user.pets if user_signed_in?
  end
end
