class Users::RegistrationsController < Devise::RegistrationsController
  # ゲストは「アカウント編集」ではなく「アカウント登録」という別物の画面・要件
  # (パスワード必須、現在のパスワード不要、削除ボタン不要)になるため、
  # 通常ユーザーの編集画面(edit)とはテンプレートを分けて出し分ける
  def edit
    return super unless resource.guest?

    render :guest_edit
  end

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

    # 「アカウント登録」という位置づけ上、ここでパスワードを空欄のまま送信できて
    # しまうと、本人の知らないランダムパスワードのままになってしまうため、
    # (編集画面と違い)パスワードは必須にする
    if params[:password].blank?
      resource.errors.add(:password, :blank)
      return false
    end

    return false unless resource.update(params)

    resource.update_column(:guest, false) if resource.saved_change_to_email?
    true
  end
end
