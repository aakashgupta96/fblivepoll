class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
			#Code for Starting a scheduled post
			Post.scheduled.order(:id).each do |post|
				post.start if ((post.start_time.to_time < Time.now.getutc) and post.can_start?)
			end

			#Update status of posts with unknown statuses
			Post.update_statuses
			Post.remove_videos
			Post.update_caption_for_site_credits
			sleep(10)
		end
	end

end
