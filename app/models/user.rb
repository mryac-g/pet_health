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

  DEFAULT_MEAL_UNIT_NAMES = %w[g 袋].freeze

  after_create :seed_default_meal_units

  # ゲストアカウントはメールアドレスがランダムなUUID込みで生成されるため、
  # 画面表示にそのまま使うと読みづらい。表示名としてはゲストかどうかで出し分ける
  def display_name
    guest? ? "ゲスト" : email.split("@").first
  end

  private

  # 食事量の単位は毎回自分で登録しなくてもすぐ使えるよう、よく使う単位をあらかじめ用意しておく
  def seed_default_meal_units
    DEFAULT_MEAL_UNIT_NAMES.each { |name| meal_units.find_or_create_by!(name: name) }
  end
end
