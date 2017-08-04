class WebhooksController < ApplicationController
  protect_from_forgery :except => :new_payment
  def new_payment
    puts params
    render :nothing => true, :status => 200, :content_type => 'text/html'
  end
end
