class Payment < ActiveRecord::Base
  belongs_to :user
  #after_create :update_user_subscription

  enum status: [:waiting_ipn, :pending, :failed, :denied, :refunded, :completed, :unknown]

  def update_user_subscription
    @user = self.user
    @user.update(subscription_date: Date.current, subscription_duration: 30)
    if self.amount == CONSTANT::DONOR_COST
      @user.donor!
    elsif self.amount == CONSTANT::PREMIUM_COST
      @user.premium!
    elsif self.amount == CONSTANT::ULTIMATE_COST
      @user.ultimate!
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
