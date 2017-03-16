class Post < ActiveRecord::Base
	mount_uploader :audio, AudioUploader
	has_many :compare_objects
	has_many :counters
	belongs_to :user

	def self.live
		where(live: true)
	end

	def stop
		Resque.workers.find_all{ |worker| worker.queues[0]=="start_stream" and worker.job["payload"]["args"].first==self.id }.each do |worker| 
			process_id = worker.pid
			3.times do
				process_id = %x[pgrep -P #{process_id}]
				process_id = process_id.strip.to_i
				break if process_id == 0
			end
			unless process_id==0
				begin
					self.graph_with_page_token.graph_call("#{post.video_id}", {end_live_video: "true"},"post")
    		rescue
   				100.times do
   					puts "Error ocurred while stopping"
   				end
   			end
				%x[kill -9 #{process_id}]	
			end
		end	
		self.live = false
		self.save!
	end

	def start
		graph = graph_with_page_token
		video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption} \nMade with: www.shurikenlive.com", title: self.title},"post")
    self.key = video["stream_url"]
    self.video_id = graph.graph_call("#{video["id"]}?fields=video")["video"]["id"] 
    self.save!
    Resque.enqueue(StartStream,self.id)
    Resque.enqueue(UpdateFrame,self.id)
    Resque.enqueue(NotifyAdmins,self.video_id) 
	end

	def can_start?
		start = update = 0
    Resque::Worker.all.each do |worker| 
      unless worker.working?
        start = 1 if worker.queues.first == "start_stream"
        update = 1 if worker.queues.first == "update_frame"
      end
      return true if start==1 and update==1
    end
    return false
	end

	def graph_with_page_token
		graph = Koala::Facebook::API.new(self.user.token)
		page_access_token = graph.get_page_access_token(self.page_id)
		graph = Koala::Facebook::API.new(page_access_token) 			
	end
end
