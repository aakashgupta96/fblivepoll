# Load the Rails application.
require File.expand_path('../application', __FILE__)
require 'koala'
require 'carrierwave/orm/activerecord'
require "rubygems"
require "headless"
require "selenium-webdriver"
require 'process_exists'
require 'socket'
Rails.application.initialize!
ActionMailer::Base.smtp_settings = {
    address:              'smtp.gmail.com', #'email-smtp.us-west-2.amazonaws.com',
    port:                 587,
    user_name:            ENV["GMAIL_USERNAME"],
  	password:             ENV["GMAIL_PASSWORD"],
    authentication:       :login,#:plain,
    enable_starttls_auto: true
}


#Resque.enqueue(LoopTask)