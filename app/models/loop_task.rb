class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
			#Code for Starting a scheduled post
			Post.scheduled.each do |post|
				post.start if ((post.start_time.to_time < Time.now.getutc)  and (post.image != nil) and post.can_start?)
			end
			Post.live.each do |post|
				query = "https://graph.facebook.com/v2.8/?ids=#{post.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{post.user.token}"
				post.stop("Deleted from FB") if HTTParty.get(query).parsed_response['data'].nil?
			end
			sleep(10)
		end
	end

end
