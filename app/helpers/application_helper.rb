module ApplicationHelper
	def current_user_is_donor?
		if current_user
			return current_user.member?	? false : true
		else
			return false
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
		elsif post.live
			"Live"
		else
			"Unknown and yet to be confirmed"
		end
	end

end
