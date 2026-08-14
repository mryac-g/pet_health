class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :pets, dependent: :destroy
  has_many :meal_types, dependent: :destroy
  has_many :meal_units, dependent: :destroy
  has_many :medicine_types, dependent: :destroy
  has_many :hospital_names, dependent: :destroy
  has_many :vaccine_types, dependent: :destroy

  # ゲストアカウントはメールアドレスがランダムなUUID込みで生成されるため、
  # 画面表示にそのまま使うと読みづらい。表示名としてはゲストかどうかで出し分ける
  def display_name
    guest? ? "ゲスト" : email.split("@").first
  end
end
