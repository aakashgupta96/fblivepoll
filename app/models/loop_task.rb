class LoopTask
	@queue = :loop_task

	def self.perform 
	  loop do
	  	#Code for Stopping a streaming process
			Resque.workers.find_all{ |worker| worker.queues[0]=="start_stream" }.each do |worker|
				process_id = worker.pid
				3.times do
					process_id = %x[pgrep -P #{process_id}]
					process_id = process_id.strip.to_i
					break if process_id == 0
				end
				unless process_id==0
					elapsed_time = %x[ps -p #{process_id} -o etime=]
					elapsed_time = LoopTask.convert_to_sec(elapsed_time.strip!)
					post_id = LoopTask.retrieve_post_id(worker)
					post = Post.find(post_id)
					duration = (post.duration-30.years).to_i
					if(elapsed_time >= duration)
						begin
							post.graph_with_page_token.graph_call("#{post.video_id}", {end_live_video: "true"},"post")
    				rescue
    					
    				end
						post.stop
					end
				end
			end

			#Code for Starting a scheduled post
			Post.scheduled.each do |post|
				if(post.start_time.to_time < Time.now.getutc)
					post.start if post.can_start?
				end
			end
			sleep(5)
		end
	end

	def self.retrieve_post_id(worker)
		worker.job["payload"]["args"].first
	end

	def self.convert_to_sec(time)
		a,b,c = time.split(":").map{|str| str.to_i}
		return ((a*3600)+(b*60)+c) unless c.nil?
		return ((a*60) + b) unless b.nil?
		return a
	end
end
