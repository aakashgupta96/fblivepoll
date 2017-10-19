class Payment < ActiveRecord::Base
  belongs_to :user
  validates :payment_id, uniqueness: true
  #after_create :update_user_subscription

  enum status: [:waiting_ipn, :pending, :failed, :expired, :refunded, :completed, :unknown, :cancelled]

  def update_user_subscription(plan_name)
    user = self.user
    user.update(subscription_date: Date.current, subscription_duration: 30)
    if Constant::DONOR_PLAN_NAME == plan_name
      user.donor!
    elsif Constant::PREMIUM_PLAN_NAME == plan_name
      user.premium!
    elsif Constant::ULTIMATE_PLAN_NAME == plan_name
      user.ultimate!
    end
  end
  
  def self.get_paypal_token
    auth = {
      username: ENV["PAYPAL_CLIENT_ID"],
      password: ENV["PAYPAL_CLIENT_SECRET"]
    }
    headers = {
      "Accept" => "application/json", 
      "Accept-Language" => "en_US"
    }
    response = HTTParty.post("#{ENV['PAYPAL_API_BASE_URL']}/oauth2/token",headers: headers, basic_auth: auth, body: "grant_type=client_credentials")
    return response.parsed_response["access_token"]
  end

  def verify_from_paypal
    token = Payment.get_paypal_token
    headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer #{token}"
    }
    response = HTTParty.get("#{ENV['PAYPAL_API_BASE_URL']}/payments/payment/#{self.payment_id}", headers: headers)
    payment_status = response.parsed_response["state"]
    set_status_from_paypal(payment_status)
    if response.ok? & self.completed?
      plan_name = response.parsed_response["transactions"].first["item_list"]["items"].first["name"]
      update_user_subscription(plan_name)
      return true
    else
      return false
    end
  end

  def set_status_from_instamojo(received_text)
    case received_text
    when "Failed"
      self.status = "failed"
    when "Credit"
      self.status = "completed"
    else
      self.status = "pending"
    end
  end

  def set_status_from_paypal(payment_status)
    return unless self.waiting_ipn?
    case payment_status
    when "approved"
      self.completed!
    when "pending"
      self.pending!
    when "failed"
      self.failed!
    when "expired"
      self.expired!
    when "cancelled"
      self.cancelled
    when "refunded"
      self.refunded!
    else
      payment.unknown!
    end
  end

end
