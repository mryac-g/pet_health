class Inquiry < ApplicationRecord
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  belongs_to :user

  validates :name, presence: true
  validates :email, presence: true, format: { with: EMAIL_FORMAT }
  validates :message, presence: true
end
