class WebhooksController < ApplicationController
  protect_from_forgery :except => :new_payment
  def new_payment
    byebug
    response = validate_IPN_notification(request.raw_post)
    case response
    when "VERIFIED"
      puts 'worked'
    when "INVALID"
       puts 'did not work'
    else
    end
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end

  protected 



  def validate_IPN_notification(raw)

    uri = URI.parse('https://ipnpb.sandbox.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    #uri = URI.parse('https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
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
