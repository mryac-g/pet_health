class Admin::InquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @inquiries = Inquiry.order(created_at: :desc)
  end

  def show
    @inquiry = Inquiry.find(params[:id])
  end
end
