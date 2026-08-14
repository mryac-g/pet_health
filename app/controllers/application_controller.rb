class ApplicationController < ActionController::Base
  before_action :set_pets_for_sidebar

  private

  # サイドバーのペット切り替えはどのページでも常に表示したいため、ログイン中は
  # 常に@petsを用意しておく。ビュー側での初回アクセスをBulletにN+1と誤検知され
  # ないよう、ここ(コントローラ)でロードを済ませておく
  def set_pets_for_sidebar
    @pets = current_user.pets.to_a if user_signed_in?
  end
end
