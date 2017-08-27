class Constant < ActiveRecord::Base
	
	MEMBER_POST_LIMIT = 1
  DONOR_POST_LIMIT = 1
  PREMIUM_POST_LIMIT = 1
  ULTIMATE_POST_LIMIT = 2
  ADMIN_POST_LIMIT = 10

  DONOR_COST = 20
  PREMIUM_COST = 30
  ULTIMATE_COST = 40
  
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
  
end
