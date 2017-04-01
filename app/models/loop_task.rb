class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
			#Code for Starting a scheduled post
			Post.scheduled.each do |post|
				post.start if ((post.start_time.to_time < Time.now.getutc)  and (post.image != nil) and post.can_start?)
			end
			sleep(5)
		end
	end

end
