class ApplicationController < ActionController::Base
  before_action :set_pets_for_sidebar
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  # サイドバーのペット切り替えはどのページでも常に表示したいため、ログイン中は
  # 常に@petsを用意しておく。ビュー側での初回アクセスをBulletにN+1と誤検知され
  # ないよう、ここ(コントローラ)でロードを済ませておく
  def set_pets_for_sidebar
    @pets = current_user.pets.to_a if user_signed_in?
  end

  def require_admin!
    redirect_to root_path, alert: "権限がありません" unless user_signed_in? && current_user.admin?
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
