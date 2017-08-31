class PaymentsController < ApplicationController
  
  protect_from_forgery :except => :receive_IPN
  
  def create
    payment = Payment.create(user_id: params[:user_id], payment_id: params[:payment_id], amount: params[:amount], tx_id: params[:tx_id])
    data = Hash.new
    data["payment_id"] = payment.payment_id
    data["tx_id"] = payment.tx_id
    data["amount"] = payment.amount
    data["user_id"] = payment.user_id
    render json: data
  end

  def receive_IPN
    puts params
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

end
