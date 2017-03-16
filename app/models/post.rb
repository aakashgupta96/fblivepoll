class Post < ActiveRecord::Base
	#mount_uploader :background, BackgroundUploader
	mount_uploader :audio, AudioUploader
	has_many :compare_objects
	has_many :counters
	belongs_to :user

	def self.live
		where(live: true)
	end

	def stop
		Resque.workers.find_all{ |worker| worker.queues[0]=="start_stream" and worker.job["payload"]["args"].first==id }.each do |worker| 
			process_id = worker.pid
			3.times do
				process_id = %x[pgrep -P #{process_id}]
				process_id = process_id.strip.to_i
				break if process_id == 0
			end
			unless process_id==0
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
		self.live=false
		self.save!
	end

end
