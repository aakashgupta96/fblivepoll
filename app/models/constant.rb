class Constant < ActiveRecord::Base
	
	MEMBER_POST_LIMIT = 1
  DONOR_POST_LIMIT = 1
  PREMIUM_POST_LIMIT = 1
  ULTIMATE_POST_LIMIT = 2
  ADMIN_POST_LIMIT = 10

  MEMBER_SCHEDULED_POST_LIMIT = 1
  DONOR_SCHEDULED_POST_LIMIT = 5
  PREMIUM_SCHEDULED_POST_LIMIT = 10
  ULTIMATE_SCHEDULED_POST_LIMIT = 20
  ADMIN_SCHEDULED_POST_LIMIT = 50

  MEMBER_LIVE_STREAM_LIMIT = 1
  DONOR_LIVE_STREAM_LIMIT = 2
  PREMIUM_LIVE_STREAM_LIMIT = 3
  ULTIMATE_LIVE_STREAM_LIMIT = 5
  ADMIN_LIVE_STREAM_LIMIT = 10

  DONOR_COST = 20
  PREMIUM_COST = 30
  ULTIMATE_COST = 40
  DONOR_PLAN_NAME = "Donor Pack"
  PREMIUM_PLAN_NAME = "Premium Pack"
  ULTIMATE_PLAN_NAME = "Ultimate Pack"
  DONOR_ARRAY = [20,1300,"Donor Pack"]
  PREMIUM_ARRAY = [30,1900,"Premium Pack"]
  ULTIMATE_ARRAY = [40,2500,"Ultimate Pack"]

  POST_PER_PAGE = 9
  USER_PER_PAGE = 100
  BIGPAGES_PER_PAGE = 20

  RTMP_TEMPLATE_IDS = [14]
  
  ALREADY_LIVE_MESSAGE = "You already have max. number of ongoing live post(s). Please try after that live video ends."
  ALREADY_SCHEDULED_MESSAGE = "You already have max. number of scheduled post(s)."
  NO_SLOT_AVAILABLE_MESSAGE = "Sorry! All slots are taken. You can schedule your post and it will be posted after scheduled time as soon as a slot will be available OR try after sometime."
  USER_BANNED_MESSAGE = "You are temporarily banned! Please contact our support center for more information."
  PAGE_NOT_FOUND_MESSAGE = "Page requested not found"
  AUTHENTICATION_FAILED_MESSAGE = "You need to sign in before continuing"
  AUTHORIZATION_FAILED_MESSAGE = "Unauthorized"
  INVALID_TEMPLATE_MESSAGE = "Invalid Selection of Template !!!"
  FB_DECLINED_REQUEST_MESSAGE = "Facebook declined your request. Please visit My Post section to see the status."
  UNAUTHORIZED_USER_FOR_TEMPLATE_MESSAGE = "You need to be a PREMIUM Member to use this template."
  POST_PUSHED_MESSAGE = "Live Video has been pushed to QUEUE."
  POST_STOPPED_MESSAGE = "Live Video has been successfully stopped."
  POST_DESTROYED_MESSAGE = "Live Video has been successfully destroyed."
  SCHEDULE_CANCELLED_MESSAGE = "Your scheduled post has been successfully cancelled"
  INVALID_OPERATION_MESSAGE = "Invalid operation for the selected post"
  PAYMENT_SUCCESS_MESSAGE = "Payment was successfully completed. Your account will get updated within few minutes. In case of any trouble or doubt, please contact us."
  PAYMENT_FAILURE_MESSAGE = "Payment was unsuccessful. In case of any trouble or doubt, please contact us."
  INELIGIBLE_FOR_FREE_TRIAL_MESSAGE = "You are ineligible to try our free Premium Plan trial offer."
  FREE_VIDEO_LIMIT_REACHED_MESSAGE = "You have reached the limit of free trial account. To make more lives, visit our PRICING page and SUBSCRIBE to any of the plans you want."
  DEFAULT_PROMOTION_MESSAGE = ""#To make something like this, visit www.shurikenlive.com"# and follow www.facebook.com/shurikenlive" #@[1807618226144625]"
end
