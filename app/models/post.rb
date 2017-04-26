class Post < ActiveRecord::Base
	
	mount_uploader :audio, AudioUploader
	mount_uploader :background, BackgroundUploader
	mount_uploader :video, VideoUploader
	mount_uploader :image, ImageUploader
	
	has_many :images, dependent: :destroy
	has_many :counters, dependent: :destroy
	belongs_to :user
	belongs_to :template

	accepts_nested_attributes_for :images, allow_destroy: true

	enum category: [ :poll, :loop_video ]

	scope :live,     ->{ where(live: true) }
	scope :scheduled,->{ where(status: "scheduled")}
	scope :published,->{ where(status: "published")}
	
	def stop(status="published")
		begin
      self.graph_with_page_token.graph_call("#{self.live_id}", {end_live_video: "true"},"post")
    rescue Exception => e
      #puts e.class,e.message	
    end
    self.update(status: status, live: false)
	end

	def start
		begin
			graph = graph_with_page_token
			video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption} \nMade with: www.shurikenlive.com", title: self.title},"post")
			live_id = video["id"]
		  video_id = graph.graph_call("#{video["id"]}?fields=video")["video"]["id"] 
		  self.update(key: video["stream_url"], video_id: video_id, live_id: live_id, live: true, status: "queued")
		  Resque.enqueue(UpdateFrame,self.id)
		  Resque.enqueue(NotifyAdmins,true,self.video_id)
		  return true
		rescue Exception => e
			begin 
				message =  "Facebook declined request with message #{e.message.split("message:").last.split(') ').second.split(',').first} "
			rescue
				message = "Facebook declined request"
			end
			self.update(status: message)
			return false
		end
	end

	def required_images_available?
		return true if self.loop_video?
		if self.template.id == 0
		  self.image != nil
		else
			self.images.size > 0
		end
	end

	def can_start?
		Resque::Worker.all.each do |worker| 
      unless worker.working?
        return true if worker.queues.first == "update_frame"
      end
    end
    #self.update(status: "Not published due to unavailability of slots")
    #Resque.enqueue(NotifyAdmins,false) 
    false
	end

	def page_access_token
		attempts = 0
		begin
			graph = Koala::Facebook::API.new(self.user.token)
			access_token = graph.get_page_access_token(self.page_id)
		rescue Exception => e
			attempts += 1
			retry if attempts <= 3
			raise e
		end
	end

	def graph_with_page_token
		attempts = 0
		begin
			graph = Koala::Facebook::API.new(self.user.token)
			access_token = graph.get_page_access_token(self.page_id)
			graph = Koala::Facebook::API.new(access_token) 			
		rescue Exception => e
			attempts += 1
			retry if attempts <= 3
			raise e
		end
	end
	
	def take_screenshot_of_frame
		driver,headless = open_in_browser("chrome")
		path = File.join(Rails.root,'public','uploads','post',self.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    driver.save_screenshot("#{path}/frame.png")
    driver.quit
    headless.destroy
	end

	def create_html
		images = self.images#Prepare an html for the frame of this post
    erb_file = Rails.root.to_s + "/public#{self.template.path}/frame.html.erb" #Path of erb file to be rendered
    html_file = Rails.root.to_s + "/public/uploads/post/#{self.id}/frame.html" #=>"target file name"
    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: self, images: images)
    result = ERB.new(erb_str)
    result = result.result(namespace.instance_eval { binding })
    path = File.join(Rails.root,'public','uploads','post',self.id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(html_file, 'w') do |f|
      f.write(result)
    end
   end

   def open_in_browser(browser = "firefox")
   	create_html
    headless = Headless.new
    headless.start
    attempts = 0
    begin
    	driver = Selenium::WebDriver.for browser.to_sym
    rescue Exception => e
    	attempts += 1
    	retry if attempts <= 3
    	raise e
    end
    driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{self.id}/frame.html"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,521)
    [driver,headless]
	end

end
