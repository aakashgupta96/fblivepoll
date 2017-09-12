class Post < ActiveRecord::Base
	
	paginates_per Constant::POST_PER_PAGE
	mount_uploader :audio, AudioUploader
	mount_uploader :background, BackgroundUploader
	mount_uploader :video, VideoUploader
	mount_uploader :image, ScreenshotUploader
	mount_uploader :html, HtmlPageUploader
	
	has_many :images, dependent: :destroy
	has_many :counters, dependent: :destroy
	belongs_to :user
	belongs_to :template

	accepts_nested_attributes_for :images, allow_destroy: true

	enum category: [:poll, :loop_video]
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]

	scope :ongoing, ->{ where(live: true) }

	def self.update_screenshots
		headless = Headless.new(display: rand(100))
		headless.start
		driver = Selenium::WebDriver.for :chrome
		driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
		driver.manage.window.size = Selenium::WebDriver::Dimension.new(1280,786)

		Post.poll.where("template_id != 0").order(id: :desc).each do |post|
			begin
				post.create_html
				driver.navigate.to "file://#{Rails.root.to_s}/public/uploads/post/#{post.id}/frame.html"
				sleep 0.5
				path = File.join(Rails.root,'public','uploads','post',post.id.to_s)
				FileUtils.mkdir_p(path) unless File.exist?(path)
				driver.save_screenshot("#{path}/frame.png")
				f = File.open(File.join(path,"frame.png"))
				post.image = f
				post.save
				f.close
				FileUtils.rm("#{path}/frame.png")
		  rescue Exception => e
		  	puts e.message,e.class
		  end
		end
		driver.quit
		headless.destroy
	end
	
	def self.get_live_with_reaction_count
		temp = Hash.new()
		return if Post.live.empty?
    attempts = 0
    begin
      #response = graph.get_object('me?fields=accounts.limit(100){parent_page}')
      #if response.nil? || response["accounts"].nil?
      #	temp
      #else
      #	page_ids = response["accounts"]["data"]
        ids = Array.new
        Post.live.each do |post| 
          ids << post.video_id
        end
        query = "https://graph.facebook.com/v2.8/?ids=#{ids.first(49).join(',')}&fields=reactions.limit(0).summary(total_count)&access_token=#{ENV['FB_ACCESS_TOKEN']}"
        response = HTTParty.get(query)
        response.each do |video_id,value|
	        #data_hash = {"id" => page_attrs.second["id"], "image" => page_attrs.second["picture"]["data"]["url"]}
	        temp[video_id.to_s] = value["reactions"]["summary"]["total_count"]
	      end
	      temp
	    #end
    rescue Exception => e
    	attempts += 1
      retry if attempts <= 3
      raise e 
    end
	end

	def update_status
		begin
			query = "https://graph.facebook.com/v2.8/?ids=#{self.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
			status = HTTParty.get(query)
			if status.parsed_response["#{self.video_id}"].nil?
				self.deleted_from_fb!
			else
				self.published!
			end
		rescue Exception => e
			puts e.class,e.message
		end
	end

	def self.update_statuses	
		begin
			Post.stopped_by_user.each do |p|
				p.update_status
			end
			Post.unknown.each do |p|
				query = "https://graph.facebook.com/v2.8/?ids=#{p.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{ENV["FB_ACCESS_TOKEN"]}"
				status = HTTParty.get(query)
				if status.parsed_response["#{p.video_id}"].nil?
					p.deleted_from_fb!
				else
					query_with_user_token = "https://graph.facebook.com/v2.8/?ids=#{p.video_id}&fields=reactions.type(LIKE).limit(0).summary(total_count).as(reactions_like),reactions.type(LOVE).limit(0).summary(total_count).as(reactions_love),reactions.type(WOW).limit(0).summary(total_count).as(reactions_wow),reactions.type(HAHA).limit(0).summary(total_count).as(reactions_haha),reactions.type(SAD).limit(0).summary(total_count).as(reactions_sad),reactions.type(ANGRY).limit(0).summary(total_count).as(reactions_angry)&access_token=#{p.user.token}"
					status = HTTParty.get(query_with_user_token)
					if status.ok?
						p.network_error!
					else
						p.user_session_invalid!
					end
				end
			end
    rescue Exception => e
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

	def live_on_fb?
		query = "https://graph.facebook.com/v2.8/#{self.video_id}?fields=live_status&access_token=#{self.user.token}"
		response = HTTParty.get(query)
		return response.ok? && (response.parsed_response["live_status"] == "LIVE")
	end

	def ended_on_fb?
		query = "https://graph.facebook.com/v2.8/#{self.video_id}?fields=live_status&access_token=#{self.user.token}"
		response = HTTParty.get(query)
		possible_values = ["PROCESSING","VOD", "LIVE_STOPPED"]
		return response.ok? && possible_values.include?(response.parsed_response["live_status"])
	end

	def start
		begin
			graph = graph_with_page_token
			if self.user.member?
				caption_suffix = "\n#{self.default_message}"
			else
				caption_suffix = ""
			end

			if  self.ambient?
				video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption}#{caption_suffix}", title: self.title, stream_type: "AMBIENT"},"post")
			else
				video = graph.graph_call("#{self.page_id}/live_videos",{status: "LIVE_NOW", description: "#{self.caption}#{caption_suffix}", title: self.title},"post")
			end
			live_id = video["id"]
		  video_id=graph.graph_call("#{video["id"]}?fields=video")["video"]["id"]
			self.update(key: video["stream_url"], video_id: video_id, live_id: live_id, live: true, status: "queued")
		  Resque.enqueue(StreamLive,self.id)
		  Resque.enqueue(NewLive,self.id)
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

	def can_start?
		return required_images_available? && Post.new.worker_available? && !self.user.is_already_live?
	end

	def worker_available?
    queued_jobs = Resque.size("stream_live")
    available_workers = Resque.workers.select{|worker|  worker.queues.first=="stream_live" && !worker.working?}.count
    return available_workers > queued_jobs
  end

	def page_access_token
		attempts = 0
		begin
			graph = Koala::Facebook::API.new(self.user.token)
			access_token = graph.get_page_access_token(self.page_id)
		rescue Exception => e
			attempts += 1
			retry if attempts <= 1
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
    sleep 0.5
    driver.save_screenshot("#{path}/frame.png")
    begin
    	f = File.open(File.join(path,"frame.png"))
    	self.image = f
    	self.save
    rescue
    	#ignore
    ensure
    	f.close
    	FileUtils.rm("#{path}/frame.png")
    end
    driver.quit
    headless.destroy
	end

	def create_html
		images = self.images #Prepare an html for the frame of this post
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
    begin
    	f = File.open(html_file)
    	self.html = f
    	self.save
    rescue
    	#ignore
    ensure
    	f.close
    end
   end

  def open_in_browser(browser = "firefox")
   	create_html
   	if browser == "firefox"
   		width = 1290 #850
   		height = 800 #550
   		headless = Headless.new(dimensions: "1920x1200x24")
   	else
   		width = 1280 #800
   		height = 786 #516
   		headless = Headless.new(dimensions: "1920x1200x24", display: rand(100))
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
    if Rails.env.production?
    	prefix = nil
    else
    	prefix = "file://"+ Rails.root.to_s + "/public"
    end
    driver.navigate.to "#{prefix}#{self.html.url}"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(width,height)
    [driver,headless]
	end

	def ambient?
		return (self.duration.hour*3600) + (self.duration.min*60) >= 4.hours.to_i
	end

	def self.update_caption_for_site_credits
		posts = Post.live.select{|x| x.user.member?}
		posts.each do |p|
			begin
				query = "https://graph.facebook.com/v2.8/#{p.video_id}?fields=description&access_token=#{p.user.token}"
				current_status = HTTParty.get(query).parsed_response["description"]
				caption_suffix = p.default_message
				if current_status.match(caption_suffix).nil?
					new_caption =  "#{current_status} \n #{caption_suffix}"
					query = "https://graph.facebook.com/v2.8/#{p.live_id}"
					response = HTTParty.post(query,:query => {"description" => "#{new_caption}", "access_token" => "#{p.user.token}"})
					p.update(caption: current_status)
				end
			rescue Exception => e
				puts e.message
			end
		end
	end
end