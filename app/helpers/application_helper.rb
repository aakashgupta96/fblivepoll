module ApplicationHelper
	def current_user_is_donor?
		if current_user
			return current_user.member?	? false : true
		else
			return false
		end
	end

	def hour_limit
		if current_user.admin?
			23
		elsif current_user.ultimate?
			7
		elsif current_user.premium?
			3
		elsif current_user.donor?
			1
		else
			0
		end
	end
	
	def status_message(post)
		if post.drafted?
			"Drafted"
		elsif post.published?
			"Published"
		elsif post.scheduled?
			"Scheduled"
		elsif post.stopped_by_user?
			"Stopped by user"
		elsif post.request_declined?
			"Facebook declined request for publishing live post. Contact facebook for more details."
		elsif post.deleted_from_fb?
			"Post is deleted from facebook"
		elsif post.network_error?
			"Streaming was interrupted due to network error"
		elsif post.queued?
			"Streaming is about to starting"
		elsif post.live?
			"Live"
		elsif post.user_session_invalid?
			"User's session was invalidated by Facebook."
		else
			"Unknown and yet to be confirmed"
		end
	end

end
