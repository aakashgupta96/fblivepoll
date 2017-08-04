class Payment < ActiveRecord::Base
  belongs_to :user
  #after_create :update_user_subscription

  enum status: [:waiting_ipn, :pending, :cancelled, :completed]
  
  def update_user_subscription
    @user = self.user
    @user.update(subscription_date: Date.current, subscription_duration: 1)
    if self.amount == 10
      @user.donor!
    elsif self.anmount == 20
      @user.premium!
    end
  end

end
