class Payment < ActiveRecord::Base
  belongs_to :user
  #after_create :update_user_subscription

  enum status: [:waiting_ipn, :pending, :failed, :denied, :refunded, :completed, :unknown]

  def update_user_subscription
    @user = self.user
    @user.update(subscription_date: Date.current, subscription_duration: 1)
    if self.amount == 10
      @user.donor!
    elsif self.anmount == 20
      @user.premium!
    end
  end

  def self.update_payment(params)
    payment = Payment.find_by_tx_id(params["txn_id"])
    payment_status = params["payment_status"]
    return unless payment.waiting_ipn?
    case payment_status
    when "Completed"
      payment.completed!
      payment.update_user_subscription
    when "Pending"
      payment.pending!
    when "Failed"
      payment.failed!
    when "Denied"
      payment.denied!
    when "Refunded"
      payment.refunded!
    else
      payment.unknown!
    end
  end

end
