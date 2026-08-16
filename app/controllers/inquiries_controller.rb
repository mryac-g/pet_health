class InquiriesController < ApplicationController
  before_action :authenticate_user!

  def new
    @inquiry = current_user.inquiries.build
  end

  def create
    @inquiry = current_user.inquiries.build(inquiry_params.merge(name: current_user.display_name, email: current_user.email))

    if @inquiry.save
      redirect_to new_inquiry_path, notice: "お問い合わせを受け付けました。"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:message)
  end
end
