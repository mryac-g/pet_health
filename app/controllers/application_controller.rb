class ApplicationController < ActionController::Base
  before_action :set_pets_for_sidebar

  private

  # サイドバーのペット切り替えは、ペット詳細以外の下位ページ(記録一覧・記録詳細・
  # プロフィール編集等)でも表示したいため、ログイン中は常に@petsを用意しておく
  def set_pets_for_sidebar
    @pets = current_user.pets if user_signed_in?
  end
end
