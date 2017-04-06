class Post < ActiveRecord::Base
	
	mount_uploader :audio, AudioUploader
	mount_uploader :background, BackgroundUploader
	mount_uploader :video, VideoUploader
	mount_uploader :image, ImageUploader
	
	has_many :images
	has_many :counters
	belongs_to :user
	belongs_to :template

	accepts_nested_attributes_for :images

	enum category: [ :poll, :loop_video ]

	scope :live,     ->{ where(status: "live") }
	scope :scheduled,->{ where(status: "scheduled")}
	scope :published,->{ where(status: "published")}
	
	def stop(status="published")
		begin
      self.graph_with_page_token.graph_call("#{self.live_id}", {end_live_video: "true"},"post")
    rescue Exception => e
      #puts e.class,e.message	
    end
    %x[kill -9 #{self.process_id}] 
    self.update(status: status)
	end

	def start
		begin
			graph = graph_with_page_token
			video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption} \nMade with: www.shurikenlive.com", title: self.title},"post")
			live_id = video["id"]
		  video_id = graph.graph_call("#{video["id"]}?fields=video")["video"]["id"] 
		  self.update(key: video["stream_url"], video_id: video_id, live_id: live_id)
		  Resque.enqueue(UpdateFrame,self.id) if self.poll?
		  Resque.enqueue(NotifyAdmins,true,self.video_id)
		rescue Exception => e
			self.update(status: "Facebook declined request for creating live video")
		end
	end

	def can_start?
		Resque::Worker.all.each do |worker| 
      unless worker.working?
        return true if worker.queues.first == "update_frame"
      end
    end
    self.update(status: "Not published due to unavailability of slots")
    Resque.enqueue(NotifyAdmins,false) 
    return false
	end

	def page_access_token
		graph = Koala::Facebook::API.new(self.user.token)
		access_token = graph.get_page_access_token(self.page_id)
	end

	def graph_with_page_token
		graph = Koala::Facebook::API.new(self.user.token)
		access_token = graph.get_page_access_token(self.page_id)
		graph = Koala::Facebook::API.new(access_token) 			
	end
	
end
