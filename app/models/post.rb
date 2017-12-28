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
	has_many :live_streams, dependent: :destroy
	belongs_to :template
	has_one :link, dependent: :destroy
	
	accepts_nested_attributes_for :images, allow_destroy: true
	accepts_nested_attributes_for :link, allow_destroy: true
	accepts_nested_attributes_for :live_streams, allow_destroy: true
	
	enum category: [:poll, :loop_video, :url_video]
	enum status: [:drafted, :published, :scheduled, :stopped_by_user, :request_declined, :deleted_from_fb, :network_error, :unknown, :queued, :live, :schedule_cancelled, :user_session_invalid]

	scope :ongoing, ->{ where(live: true) }

	before_save :set_default_values

	def self.migrate_changes_for_live_streams
		all.each do |post|
			post.live_streams.create(key: post.key, status: post.status, page_id: post.page_id, live_id: post.live_id, video_id: post.video_id)
		end
	end

	def set_default_values
		self.default_message = Constant::DEFAULT_PROMOTION_MESSAGE
	end

	def self.update_screenshots
		headless = Headless.new(display: rand(100))
		headless.start
		driver = Selenium::WebDriver.for :chrome
		driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
		driver.manage.window.size = Selenium::WebDriver::Dimension.new(1280,786)

		poll.where("template_id != 0").order(id: :desc).each do |post|
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
		live_facebook_posts = live.where("template_id NOT IN (?)",Constant::RTMP_TEMPLATE_IDS)
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
		live_streams.each{|ls| ls.update_status}
	end

	def change_live_streams(from: "", to: "")
		return if from.empty? || to.empty?
		live_streams.send(from.to_sym).update_all(status: LiveStream.statuses[to])
	end

	#Code for removing video files of published or other erroneous loop video posts
	# def self.remove_videos
	# 	loop_video.where(live: false).select{|p| p.status != 'scheduled' && p.status != 'drafted' && p.status != 'queued' && p.video.url != nil}.each do |post|
	# 		post.remove_video = true
	# 		post.save
	# 	end
	# end
	
	def stop(status="published")
		live_streams.where(status: [LiveStream.statuses["queued"], LiveStream.statuses["live"]]).each{|l| l.stop(status)}
    self.update(live: false, status: status)
	end

	def live_on_fb?
		#if any of the live stream has status live, return true
		live_streams.each do |ls|
			return true if ls.live_on_fb?
		end
		return false
	end

	def ended_on_fb?
		#return true if all live_streams have ended
		live_streams.each do |ls|
			return false unless ls.ended_on_fb?	
		end
		return true
	end

	# def any_valid_live_stream

	# end

	def start
		any_ls_started = false
		live_streams.each do |ls|
			any_ls_started = true if ls.start
		end
		if any_ls_started
			update(live: true)
			Resque.enqueue(StreamJob,id)
		  #Resque.enqueue(NewLive,id)
		  return true
		else
			return false
		end
	end

	def mark_live_on_fb
		live_streams.each do |ls|
			ls.mark_live_on_fb
		end
	end

	def refresh_browser
		create_html
		update(reload_browser: true)
	end

	def cancel_scheduled
		destroy if scheduled?
	end

	def required_images_available?
		return true unless poll? 
		if template.id == 0
		  self.image.url != nil
		else
			self.images.size > 0
		end
	end

	def can_start?
		return required_images_available? && !live_streams.empty? && user.worker_available? && user.has_live_post_in_limit?
	end

	def video_id
		#Assuming it is required only for live polls
		live_streams.first.video_id
	end

	def page_access_token
		#Assuming that it is required only for polls/videos containing only one live streams
		live_streams.first.page_access_token
	end
	
	def take_screenshot_of_frame
		driver,headless = open_in_browser("chrome")
		path = File.join(Rails.root,'public','uploads','post',id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    sleep 1
    driver.save_screenshot("#{path}/frame.png")
    begin
    	f = File.open(File.join(path,"frame.png"))
    	self.image = f
    	save
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
    erb_file = Rails.root.to_s + "/public#{template.path}/frame.html.erb" #Path of erb file to be rendered
    html_file = Rails.root.to_s + "/public/uploads/post/#{id}/frame.html" #=>"target file name"
    erb_str = File.read(erb_file)
    namespace = OpenStruct.new(post: self, images: images)
    result = ERB.new(erb_str)
    result = result.result(namespace.instance_eval { binding })
    path = File.join(Rails.root,'public','uploads','post',id.to_s)
    FileUtils.mkdir_p(path) unless File.exist?(path)
    File.open(html_file, 'w') do |f|
      f.write(result)
    end
    begin
    	f = File.open(html_file)
    	self.html = f
    	save
    rescue
    	#ignore
    ensure
    	f.close
    end
   end

  def open_in_browser(browser = "firefox")
  	create_html
   	if browser == "firefox"
   		width = 1290
   		height = 800
   		#profile = Selenium::WebDriver::Firefox::Profile.new; profile["toolkit.telemetry.enabled"] = false;profile["toolkit.telemetry.prompted"] = 2;profile["toolkit.telemetry.rejected"] = true
   		options = Selenium::WebDriver::Firefox::Options.new #(profile: profile)
   		headless = Headless.new(dimensions: "1920x1200x24")
   	else
   		width = 1280
   		height = 786
   		options = Selenium::WebDriver::Chrome::Options.new
   		options.add_argument("--no-sandbox")
   		headless = Headless.new(dimensions: "1920x1200x24", display: rand(100))
   	end
   	headless.start
    attempts = 0
    begin
    	client = Selenium::WebDriver::Remote::Http::Default.new(open_timeout: 180, read_timeout: 180)
    	driver = Selenium::WebDriver.for browser.to_sym, options: options, http_client: client
    rescue Exception => e
    	attempts += 1
    	sleep(2) and retry if attempts <= 3
    	raise e
    end
    prefix = get_html_url_prefix(browser)
    driver.navigate.to "#{prefix}#{self.html.url}"
    driver.manage.window.position = Selenium::WebDriver::Point.new(0,0)
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(width,height)
    %x[DISPLAY=':#{headless.display}' xdotool mousemove #{width+10} #{height+10}]
    [driver,headless]
	end

	def get_html_url_prefix(browser)
		if Rails.env.production?
    	prefix = nil
    else
    	if browser == "firefox"
    		prefix = "http://localhost:3000"
    	else
    		prefix = "file://#{Rails.root.to_s}/public"
    	end
    end
	end

	def ambient?
		return (duration.hour*3600) + (duration.min*60) > 4.hours.to_i
	end

	def from_google_drive?
		return false unless url_video?
		url = link.url
		patterns = [/https:\/\/drive\.google\.com\/file\/d\/(.*?)\/.*?\?usp=sharing/, /https:\/\/drive\.google\.com\/open\?id=(.*)/]
		patterns.each do |pattern|
			return true unless (url =~ pattern).nil?
		end	
		return false
	end

	def from_dropbox?
		return false unless url_video?
		url = link.url
		pattern = /https:\/\/www\.dropbox\.com\/s\/(.*)\/.*/
		if (url =~ pattern).nil?
			false
		else
			true
		end
	end

	def from_onedrive?
		return false unless url_video?
		url = link.url
		patterns = [/https:\/\/1drv\.ms\/v\/s!(.*?)/]
		patterns.each do |pattern|
			return true unless (url =~ pattern).nil?
		end	
		return false
	end

	def from_youtube?
		return false unless url_video?
		url = link.url
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
			query = "https://www.googleapis.com/youtube/v3/videos?key=#{ENV['GOOGLE_API_KEY']}&part=snippet&id=#{link.url.match(pattern)[7]}"
			response = HTTParty.get(query)
			return (response.ok? && response.parsed_response["items"][0]["snippet"]["liveBroadcastContent"] == "live") rescue false
		else
			return false
		end
	end

	def fb_live_to_fb?
		return false unless url_video?
		url = link.url
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
		return false unless url_video?
		url = link.url
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
		download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4' -g #{link.url} ]
		download_url.strip
	end

	def share_on(page_ids)
		begin
			attempts = 0
			url = "https://www.facebook.com/" + self.video_id
			user_graph = Koala::Facebook::API.new(user.token)
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
		#download_url = %x[youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=mp4a]/mp4,dash_hd_src' -g #{url}] #For support of FB live videos as surce video
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