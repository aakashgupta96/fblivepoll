class PaymentsController < ApplicationController
  
  protect_from_forgery :except => :create_instamojo_payment
  
  def create_instamojo_payment
    headers = {
      "X-Api-Key" => ENV["INSTAMOJO_KEY"], 
      "X-Auth-Token" => ENV["INSTAMOJO_TOKEN"]
    }
    response = HTTParty.get("#{ENV['INSTAMOJO_API_BASE_URL']}/payments/#{params[:payment_id]}", headers: headers)
    if response.ok? && response.parsed_response["success"]
      payment = Payment.new(payment_params(response.parsed_response))
      payment.tx_id = payment.payment_id
      payment.user = User.find_by_email(response.parsed_response["payment"]["buyer_email"])
      payment.set_status_from_instamojo(response.parsed_response["payment"]["status"])
      if payment.save && payment.completed? && payment.update_user_subscription(response.parsed_response["payment"]["link_title"])
        return redirect_to dashboard_path, alert: Constant::PAYMENT_SUCCESS_MESSAGE
      else
        return redirect_to dashboard_path, alert: Constant::PAYMENT_FAILURE_MESSAGE
      end
    else
      return redirect_to dashboard_path, alert: Constant::PAYMENT_FAILURE_MESSAGE
    end
  end

  def paypal_create
    payment = Payment.create(user_id: params[:user_id], payment_id: params[:payment_id], amount: params[:amount], tx_id: params[:tx_id])
    data = Hash.new
    data["payment_id"] = payment.payment_id
    data["tx_id"] = payment.tx_id
    data["amount"] = payment.amount
    data["user_id"] = payment.user_id
    render json: data
  end

  def verify_paypal_payment
    payment = Payment.find_by_payment_id(params['payment_id'])
    if payment.verify_from_paypal
      return redirect_to dashboard_path, alert: Constant::PAYMENT_SUCCESS_MESSAGE
    else
      return redirect_to dashboard_path, alert: Constant::PAYMENT_FAILURE_MESSAGE
    end
  end

  def receive_IPN
    response = validate_IPN_notification(request.raw_post)
    case response
    when "VERIFIED"
      Payment.update_payment(params)
    when "INVALID"
       puts 'did not work'
    else
    end
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  protected 

  def validate_IPN_notification(raw)
    if Rails.env.production?
      uri = URI.parse('https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    else
      uri = URI.parse('https://ipnpb.sandbox.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    end
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    response = http.post(uri.request_uri, raw,
                  				'Content-Length' => "#{raw.size}",
                        	'User-Agent' => "My custom user agent"
                       	).body
  end

  def payment_params payment
    ActionController::Parameters.new(payment).require(:payment).permit(:payment_id, :amount)
  end

end
