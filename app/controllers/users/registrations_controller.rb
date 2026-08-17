class Users::RegistrationsController < Devise::RegistrationsController
  private

  # ゲストアカウントはランダムな(本人が知らない)パスワードで作成されるため、
  # Devise標準のupdate_with_password(現在のパスワード必須)では正式登録できない。
  # ゲストの場合のみ現在のパスワード確認を省略して更新できるようにし、
  # メールアドレスが変更された(=正式なメールアドレスが設定された)場合のみ
  # guestフラグを解除する。ペット・記録は同じuser_idのまま更新するだけなので、
  # データ移行処理は不要でそのまま引き継がれる
  def update_resource(resource, params)
    return super unless resource.guest?

    params = params.except(:current_password)
    params = params.except(:password, :password_confirmation) if params[:password].blank?

    return false unless resource.update(params)

    resource.update_column(:guest, false) if resource.saved_change_to_email?
    true
  end
end
