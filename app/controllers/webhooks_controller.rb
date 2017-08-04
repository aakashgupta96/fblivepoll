class WebhooksController < ApplicationController
  protect_from_forgery :except => :recurly_notification
  def new_payment
    byebug
  end
end
