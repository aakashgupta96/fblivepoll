class PaymentsController < ApplicationController
  def create
    payment = Payment.create(user_id: params[:user_id], payment_id: params[:payment_id], amount: params[:amount])
    data = Hash.new
    data["payment_id"] = payment.payment_id
    data["amount"] = payment.amount
    data["user_id"] = payment.user_id
    render json: data
  end
end
