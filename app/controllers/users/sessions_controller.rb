class Users::SessionsController < Devise::SessionsController
  def guest
    user = User.create!(
      name: "ゲスト",
      email: "guest_#{SecureRandom.uuid}@example.com",
      password: Devise.friendly_token[0, 20],
      guest: true
    )
    sign_in(user)
    redirect_to root_path, notice: "ゲストとしてログインしました"
  end
end
