class WebhooksController < ApplicationController
  protect_from_forgery :except => :new_payment
  def new_payment
    puts params
  end
end
