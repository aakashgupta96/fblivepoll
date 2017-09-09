class StartScheduledPost
	@queue = :start_scheduled_post

	def self.perform(args=nil)
	  #Code for Starting a scheduled post
		Post.scheduled.order(:id).each do |post|
			post.start if ((post.start_time.to_time < Time.now.getutc) and post.can_start?)
		end
	end

end
