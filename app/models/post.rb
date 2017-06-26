class Post < ActiveRecord::Base
	
	paginates_per 9
	mount_uploader :audio, AudioUploader
	mount_uploader :background, BackgroundUploader
	mount_uploader :video, VideoUploader
	mount_uploader :image, ImageUploader
	
	has_many :images, dependent: :destroy
	has_many :counters, dependent: :destroy
	belongs_to :user
	belongs_to :template

	accepts_nested_attributes_for :images, allow_destroy: true

	enum category: [:poll, :loop_video]
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live]

	scope :ongoing, ->{ where(live: true) }

  def update_status
    begin
      query = "https://graph.facebook.com/v2.8/?ids=#{self.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{self.user.token}"
      status = HTTParty.get(query)
      if status.parsed_response["#{self.video_id}"].nil?
        self.deleted_from_fb!
      else
        self.published!
      end
    rescue Exception => e
      #Ignored
      puts e.class,e.message
    end
  end

	def self.update_statuses	
		begin
			Post.stopped_by_user.each do |p|
				p.update_status
			end
			Post.unknown.each do |p|
				query = "https://graph.facebook.com/v2.8/?ids=#{p.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{p.user.token}"
				status = HTTParty.get(query)
				if status.parsed_response["#{p.video_id}"].nil?
					p.deleted_from_fb!
				else
					p.network_error!
				end
			end
    rescue Exception => e
      #Ignored
      puts e.class,e.message
    end
	end

	#Code for removing video files of published or other erroneous loop video posts
	def self.remove_videos
		Post.loop_video.where(live: false).select{|p| p.status != 'scheduled' && p.status != 'drafted' && p.status != 'queued' && p.video.url != nil}.each do |post|
			post.remove_video = true
			post.save
		end
	end
	
	def stop(status="published")
		begin
      self.graph_with_page_token.graph_call("#{self.live_id}", {end_live_video: "true"},"post")
    rescue Exception => e
      puts e.class,e.message
    end
    self.update(status: status, live: false)
	end

	def start
		begin
			graph = graph_with_page_token
			if self.user.admin? || self.user.donor? || self.user.premium?
				caption_suffix = ""
			else
				caption_suffix = "\nMade with: www.shurikenlive.com"
			end
			video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption}#{caption_suffix}", title: self.title},"post")
			live_id = video["id"]
		  video_id = graph.graph_call("#{video["id"]}?fields=video")["video"]["id"] 
		  self.update(key: video["stream_url"], video_id: video_id, live_id: live_id, live: true, status: "queued")
		  Resque.enqueue(UpdateFrame,self.id)
		  #Resque.enqueue(NotifyAdmins,true,self.video_id)
		  return true
		rescue Exception => e
			puts e.class,e.message
      self.request_declined!
			return false
		end
	end

	def refresh_browser
		self.create_html
		self.update(reload_browser: true)
	end

	def cancel_scheduled
		self.destroy if self.scheduled?
	end

	def required_images_available?
		return true if self.loop_video?
		if self.template.id == 0
		  self.image.url != nil
		else
			self.images.size > 0
		end
	end

	def worker_available?
		queued_jobs = Resque.size("update_frame")
		available_workers = Resque.workers.select{|worker|  worker.queues.first=="update_frame" && !worker.working?}.count
		return available_workers > queued_jobs
	end

	def can_start?
		return required_images_available? && worker_available? && !self.user.is_already_live?
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
		images = self.images #Prepare an html for the frame of this post
    if self.poll?
      erb_file = Rails.root.to_s + "/public#{self.template.path}/frame.html.erb" #Path of erb file to be rendered
    else
      erb_file = Rails.root.to_s + "/public/videos/loop_video_frame.html.erb"
    end
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
   	if browser == "firefox"
   		headless = Headless.new
   	else
   		headless = Headless.new(display: rand(100))
   	end
    headless.start
    attempts = 0
    begin
    	driver = Selenium::WebDriver.for browser.to_sym
    rescue Exception => e
    	attempts += 1
    	sleep(2) and retry if attempts <= 3
    	raise e
    end
    driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{self.id}/frame.html"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(800,521)
    [driver,headless]
	end

end