# Load the Rails application.
require File.expand_path('../application', __FILE__)
require "rmagick"
require 'koala'
require 'carrierwave/orm/activerecord'
require 'frame'
Rails.application.initialize!

ActionMailer::Base.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'gmail.com',
    user_name:            ENV["GMAIL_USERNAME"],
    password:             ENV["GMAIL_PASSWORD"],
    authentication:       :plain,
    enable_starttls_auto: true
}


Resque.enqueue(StopStream)
