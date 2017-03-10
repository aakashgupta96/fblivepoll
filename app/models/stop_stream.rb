class StopStream
	@queue = :stop_stream

	def self.perform 
	  loop do
			Resque.workers.find_all{ |worker| worker.queues[0]=="start_stream" }.each do |worker|
				process_id = worker.pid
				3.times do
					process_id = %x[pgrep -P #{process_id}]
					process_id = process_id.strip.to_i
					break if process_id == 0
				end
				unless process_id==0
					elapsed_time = %x[ps -p #{process_id} -o etime=]
					elapsed_time.strip!
					elapsed_time = StopStream.convert_to_sec(elapsed_time)
					post_id = StopStream.retrieve_post_id(worker)
					post = Post.find(post_id)
					duration = (post.duration-30.years).to_i
					if(elapsed_time >= duration)
						begin
						graph = Koala::Facebook::API.new(post.user.token)
						page_access_token = graph.get_page_access_token(post.page_id)
    					graph = Koala::Facebook::API.new(page_access_token)
    					graph.graph_call("#{post.video_id}", {end_live_video: "true"},"post")
    					rescue
    						
    					end
						%x[kill -9 #{process_id}]	
					end
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
		if c.nil?
			if b.nil?
				a
			else
				(a*60) + b
			end
		else
			(a*3600)+(b*60)+c
		end
	end
end
