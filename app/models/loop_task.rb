class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
			#Code for Starting a scheduled post
			Post.scheduled.order(:id).each do |post|
				post.start if ((post.start_time.to_time < Time.now.getutc)  and (post.required_images_available?) and post.can_start?)
			end	
			sleep(10)
		end
	end

end
