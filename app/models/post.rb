	class Post < ActiveRecord::Base
	
	paginates_per Constant::POST_PER_PAGE

	mount_uploader :audio, AudioUploader
	mount_uploader :background, BackgroundUploader
	mount_uploader :video, VideoUploader
	mount_uploader :image, ScreenshotUploader
	mount_uploader :html, HtmlPageUploader
	
	has_many :images, dependent: :destroy
	has_many :counters, dependent: :destroy
	has_many :shared_posts, dependent: :destroy
	belongs_to :user
	belongs_to :template
	has_one :link, dependent: :destroy
	
	accepts_nested_attributes_for :images, allow_destroy: true
	accepts_nested_attributes_for :link, allow_destroy: true
	
	enum category: [:poll, :loop_video, :url_video]
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]

	scope :ongoing, ->{ where(live: true) }

	before_save :set_default_values

	def set_default_values
		self.default_message = Constant::DEFAULT_PROMOTION_MESSAGE
	end

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
		live_facebook_posts = Post.live.where("template_id NOT IN (?)",Constant::RTMP_TEMPLATE_IDS)
		return if live_facebook_posts.empty?
    attempts = 0
    begin
      ids = Array.new
      live_facebook_posts.each do |post| 
        ids << post.video_id
      end
      query = "https://graph.facebook.com/v2.8/?ids=#{ids.first(49).join(',')}&fields=reactions.limit(0).summary(total_count)&access_token=#{ENV['FB_ACCESS_TOKEN']}"
      response = HTTParty.get(query)
      response.each do |video_id,value|
        temp[video_id.to_s] = value["reactions"]["summary"]["total_count"]
      end
      temp
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
      self.graph_with_page_token.graph_call("#{self.live_id}", {end_live_video: "true"},"post") unless Constant::RTMP_TEMPLATE_IDS.include?(self.template.id)
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
		if Constant::RTMP_TEMPLATE_IDS.include?(self.template.id)
			self.update(live: true, status: "queued")
			Resque.enqueue(StreamLive,self.id)
		  Resque.enqueue(NewLive,self.id)
		  return true
		else
			begin
				graph = graph_with_page_token
				if self.user.member?
					caption_suffix = "\n #{self.default_message}"
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
	end

	def refresh_browser
		self.create_html
		self.update(reload_browser: true)
	end

	def cancel_scheduled
		self.destroy if self.scheduled?
	end

	def required_images_available?
		return true unless self.poll? 
		if self.template.id == 0
		  self.image.url != nil
		else
			self.images.size > 0
		end
	end

	def can_start?
		return required_images_available? && Post.new.worker_available? && self.user.has_live_post_in_limit?
	end

	def worker_available?
    queued_jobs = Resque.size("stream_live")
    available_workers = Resque.workers.select{|worker|  worker.queues.include?("stream_live") && !worker.working?}.count
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
   		profile = Selenium::WebDriver::Firefox::Profile.new
   		profile["toolkit.telemetry.enabled"] = false
   		profile["toolkit.telemetry.prompted"] = 2
   		profile["toolkit.telemetry.rejected"] = true
   		options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
   		headless = Headless.new(dimensions: "1920x1200x24")
   	else
   		width = 1280 #800
   		height = 786 #516
   		options = Selenium::WebDriver::Chrome::Options.new
   		options.add_argument("--no-sandbox")
   		headless = Headless.new(dimensions: "1920x1200x24", display: rand(100))
   	end
   	headless.start
    attempts = 0
    begin
    	driver = Selenium::WebDriver.for browser.to_sym, options: options
    rescue Exception => e
    	attempts += 1
    	sleep(2) and retry if attempts <= 3
    	raise e
    end
    if Rails.env.production?
    	prefix = nil
    else
    	if browser == "firefox"
    		prefix = "http://localhost:3000"
    	else
    		prefix = "file://#{Rails.root.to_s}/public"
    	end
    end

    driver.navigate.to "#{prefix}#{self.html.url}"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(width,height)
    %x[DISPLAY=':#{headless.display}' xdotool mousemove #{width+10} #{height+10}]
    [driver,headless]
	end

	def ambient?
		return (self.duration.hour*3600) + (self.duration.min*60) >= 4.hours.to_i
	end

	def self.update_caption_for_site_credits
		posts = Post.live.select{|x| ((x.user.member?)&&(!Constant::RTMP_TEMPLATE_IDS.include?(x.template.id)))}
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

	def from_google_drive?
		return false unless self.url_video?
		url = self.link.url
		patterns = [/https:\/\/drive\.google\.com\/file\/d\/(.*?)\/.*?\?usp=sharing/, /https:\/\/drive\.google\.com\/open\?id=(.*)/]
		patterns.each do |pattern|
			return true unless (url =~ pattern).nil?
		end	
		return false
	end

	def from_dropbox?
		return false unless self.url_video?
		url = self.link.url
		pattern = /https:\/\/www\.dropbox\.com\/s\/(.*)\/.*/
		if (url =~ pattern).nil?
			false
		else
			true
		end
	end

	def from_onedrive?
		return false unless self.url_video?
		url = self.link.url
		patterns = [/https:\/\/1drv\.ms\/v\/s!(.*?)/]
		patterns.each do |pattern|
			return true unless (url =~ pattern).nil?
		end	
		return false
	end

	def from_youtube?
		return false unless self.url_video?
		url = self.link.url
		pattern = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*/
		if (url =~ pattern).nil?
			false
		else
			true
		end
	end

	def youtube_live_to_fb?
		if from_youtube?
			pattern = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#\&\?]*).*/
			query = "https://www.googleapis.com/youtube/v3/videos?key=#{ENV['GOOGLE_API_KEY']}&part=snippet&id=#{self.link.url.match(pattern)[7]}"
			response = HTTParty.get(query)
			return (response.ok? && response.parsed_response["items"][0]["snippet"]["liveBroadcastContent"] == "live") rescue false
		else
			return false
		end
	end

	def fb_live_to_fb?
		return false unless self.url_video?
		url = self.link.url
		pattern = /^.*(https:)\/\/(www|m)\.(facebook\.com)\/(([a-zA-Z0-9]*)\/videos\/)?([0-9]*).*/
		post_id = url.match(pattern)[6] rescue nil
		if post_id.nil? || post_id.empty?
			false
		else
			query = "https://graph.facebook.com/v2.8/#{post_id}?fields=live_status&access_token=#{ENV['FB_ACCESS_TOKEN']}"
			response = HTTParty.get(query)
			return response.ok? && (response.parsed_response["live_status"] == "LIVE")
		end
	end

	def periscope_to_fb?
		return false unless self.url_video?
		url = self.link.url
		pattern = /https?:\/\/(?:www\.)?(?:periscope|pscp)\.tv\/[^\/]+\/([a-zA-Z0-9]*[^\/?#])/
		if (url =~ pattern).nil?
			false
		else
			true
		end
	end

	def source_file_is_live?
		return youtube_live_to_fb? || periscope_to_fb? #|| fb_live_to_fb?
	end


	def get_file_url
		if from_google_drive?
			patterns = [/https:\/\/drive\.google\.com\/file\/d\/(.*?)\/.*?\?usp=sharing/, /https:\/\/drive\.google\.com\/open\?id=(.*)/]
			patterns.each do |pattern|
				if self.link.url.match pattern
					return "https://drive.google.com/uc?export=download&id=" + self.link.url.match(pattern)[1]
				end
			end	
		elsif from_dropbox?
			self.link.url.split("?").first + "?dl=1"
		elsif from_onedrive?
			begin
				res = Net::HTTP.get_response(URI(self.link.url))
				res['location'].gsub("redir","download")
			rescue
				false
			end
		else
			#download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4,dash_hd_src' -g #{self.link.url} ]
			download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4' -g #{self.link.url} ]
			download_url.strip
		end
	end

	def share_on(page_ids)
		begin
			attempts = 0
			url = "https://www.facebook.com/" + self.video_id
			user_graph = Koala::Facebook::API.new(self.user.token)
			page_ids.each do |page_id|
				begin
					access_token = user_graph.get_page_access_token(page_id)
					graph = Koala::Facebook::API.new(access_token)
					response = graph.put_wall_post("",link: url)
					self.shared_posts << SharedPost.create(shared_post_id: response["id"])
				rescue Exception => e
					puts e.message
					attempts += 1
					retry if attempts <= 3
					raise e
				end
			end
		rescue Exception => e
			puts e.message
			return false
		end
		return true
	end

	def self.validate_url(url)
		#download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4,dash_hd_src' -g #{url}]
		download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4' -g #{url}]
		download_url.strip!
		if (download_url.empty? || Post.from_google_drive(url))
			return false
		else
			return true
		end
	end

	def self.from_google_drive(url)
		patterns = [/https:\/\/drive\.google\.com\/file\/d\/(.*?)\/.*?\?usp=sharing/, /https:\/\/drive\.google\.com\/open\?id=(.*)/]
		patterns.each do |pattern|
			return true unless (url =~ pattern).nil?
		end
		return false
	end

end