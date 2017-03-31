class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
			#Code for Starting a scheduled post
			Post.scheduled.each do |post|
				if(post.start_time.to_time < Time.now.getutc)
					post.start if post.can_start?
				end
			end
			sleep(5)
		end
	end

end
