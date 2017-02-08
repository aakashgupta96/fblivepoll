class StopStream

	@queue = :stop_stream

	def self.perform 
		loop do
			Resque.workers.find_all{ |worker| worker.queues[0]=="start_stream" }.each do |worker|
				x = worker.pid
				3.times do
					x = %x[pgrep -P #{x}]
					if x.empty?
						x = x.to_i
						break
					end
					x = x.chomp
					x = x.to_i
				end
				unless x==0
					elapsed_time = %x[ps -p #{x} -o etime=]
					elapsed_time.strip!
					elapsed_time = StopStream.convert_to_sec(elapsed_time)
					post_id = StopStream.retrieve_post_id(worker)
					p = Post.find(post_id)
					duration = (p.duration-30.years).to_i
					#puts "Duration is ",duration," and elapsed_time is ",elapsed_time
					if(elapsed_time >= duration)
						graph = Koala::Facebook::API.new(p.user.token)
						page_access_token = graph.get_page_access_token(p.page_id)
    					graph = Koala::Facebook::API.new(page_access_token)
    					graph.graph_call("#{p.video_id}", {end_live_video: "true"},"post")
						%x[kill -9 #{x}]	
					end
				end
			end
			sleep(5)
		end
	end

	def self.retrieve_post_id worker
		worker.job["payload"]["args"].first
	end

	def self.convert_to_sec time
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
